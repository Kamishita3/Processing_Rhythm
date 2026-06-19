//音楽再生用ライブラリ
import ddf.minim.*;
Minim minim;
AudioPlayer player;

PImage emoji;

//初期ページ指定
String Page = "Title";

void setup() {
    frameRate(120);
    size(500, 500);
    emoji = loadImage("thinking.png");
}

void draw() {
    //背景色
    background(0, 0, 88);

    if (Page == "Title") Title();

    if (Page == "Select") Select();

    if (Page == "Play") Play();
}

void Title() {
    //タイトル画面
    textFont(createFont("BIZ UDゴシック Bold", 64));
    textSize(64);
    textAlign(CENTER);
    text("音ゲー", width/2, height/3);
    textSize(32);
    text("Press any key to Start", width/2, height * 2/3);


    //セレクト画面読み込み
    if (keyPressed) {
        Page = "Select";

        keyCode = 0;
        key = 0;
    }
}

//曲データ読み込み変数
JSONArray songdatas;
JSONObject songdata;
int selectsong = 0;

//曲データ読み込みフラグ
boolean loadsongs = false;

void Select() {

    //曲データ読み込み
    if (!loadsongs) {
        songdatas = loadJSONArray("songdata.json");

        //確認用
        for (int i = 0; i < songdatas.size(); ++i) {
            songdata = songdatas.getJSONObject(i);

            println((i + 1) + "曲目");
            println("id:" + songdata.getString("id"));
            println("曲名:" + songdata.getString("name"));
            println("BPM:" + songdata.getFloat("bpm"));
            println("曲長:" + songdata.getString("length"));
            println("diff:" + songdata.getString("diff"));

        }

        loadsongs = true;

    }

    //セレクト画面
    songdata = songdatas.getJSONObject(selectsong);

    textFont(createFont("BIZ UDゴシック Bold", 64));
    textSize(20);
    textAlign(CENTER);
    text(songdata.getString("name"), width/4, height/2);

    textFont(createFont("BIZ UDゴシック", 64));
    textSize(32);
    if (selectsong != 0) text("Δ", width/4, height/2 - 70);
    if (selectsong != songdatas.size() - 1) text("∇", width/4, height/2 + 70);

    textSize(24);
    text("BPM:" + songdata.getFloat("bpm"), width * 3/4, height * 3.5/5);
    text("曲長:" + songdata.getString("length"), width * 3/4, height * 4/5);
    textSize(32);
    text("難易度:" + songdata.getString("diff"), width * 3/4, height/2);

    textSize(24);
    textAlign(LEFT);
    text("↑/↓: 選曲  ENTER: スタート", 0 , height);

    if (keyPressed) {
        if (keyCode == UP && selectsong != 0) --selectsong;

        if (keyCode == DOWN && selectsong != songdatas.size() - 1) ++selectsong;

        if (key == ENTER) Page = "Play";

        keyCode = 0;
        key = 0;
    }
}

//曲読み込みフラグ
boolean gamestart = false;

//譜面読み込み変数
JSONObject chartdatas;
JSONArray notes;
JSONArray bpms;
float bpm;
float rhythmbeat;
IntList barbeats = new IntList();
FloatList barlines = new FloatList();
FloatList notex = new FloatList();
FloatList notey = new FloatList();

//譜面描画用
float dy = 0;
IntList hidenotes = new IntList();

//オプション
float offset = 0;
float hispeed = 1.5;
float judgegood = 80;
float judgecool = 60;
float judgebest = 40;

//操作
boolean key1, key2, key3, key4;

//リザルトカウント
IntList bestcount = new IntList();
IntList coolfastcount = new IntList();
IntList coollatecount = new IntList();
IntList goodfastcount = new IntList();
IntList goodlatecount = new IntList();
IntList misscount = new IntList();


void Play() {
    if (!gamestart) {
        //println(songdata);

        chartdatas = loadJSONObject("music/" + songdata.getString("id") + ".json");

        notes = chartdatas.getJSONArray("note");
        //println(notes);

        bpms = chartdatas.getJSONArray("time");
        bpm = bpms.getJSONObject(0).getFloat("bpm");    //今回はbpmが一定の曲しか扱わないとする
        rhythmbeat = 1;                                 //今回は4/4拍子で固定とする
        //println(bpm);

        offset = songdata.getFloat("offset");
        //println(offset);

        //小説線を引きたい(小説線の間隔はbpmのpxとする)
        //ソフランはbeatmania方式とする

        //最終小節探し
        for (int i = 0; i < notes.size(); ++i) {
            try {
                //println(notes.getJSONObject(i).getJSONArray("beat").getInt(0));
                barbeats.append(notes.getJSONObject(i).getJSONArray("beat").getInt(0));
                barbeats.append(notes.getJSONObject(i).getJSONArray("endbeat").getInt(0));

            } catch (Exception e) {
                //endbeatがない時は握りつぶす想定
                //e.printStackTrace();

            }

            hidenotes.set(i, 0);
        }
        
        //println(barbeats);
        //println(barbeats.max());

        //描画設定
        stroke(255);
        strokeCap(SQUARE);

        //曲スタート
        minim = new Minim(this);
        player = minim.loadFile("music/" + songdata.getString("id") + ".mp3");
        try {
            player.play();

        } catch (Exception e) {
            //音声出力デバイスがない場合は握りつぶす想定
            //e.printStackTrace();

        }

        gamestart = true;
    }


    //1度のみで良いものはifの中へ
    //何回も繰り返す必要のあるものはこちらへ(描画など)

    //小節線描画
    strokeWeight(1);
    for (int i = 0; i < barbeats.max() + 1; ++i){

        //小説線の初期位置y座標を列挙(ex:0,100,200,300,...)
        barlines.set(i, hispeed * -1 * i * bpm - offset * 1);

        //負荷軽減
        if (-100 < barlines.get(i) + dy && barlines.get(i) + dy < height + 100) {
            line(0, barlines.get(i) + dy, width, barlines.get(i) + dy);
            //text(i, 50, barlines.get(i) + dy);
        }
    }

    //println(barlines);

    //操作説明描画
    textSize(24);
    textAlign(CENTER);
    text("D", width/8, height - 5);
    text("F", width * 3/8, height - 5);
    text("J", width * 5/8, height - 5);
    text("K", width * 7/8, height - 5);

    //ノーツ描画
    strokeWeight(32);
    for (int i = 0; i < notes.size(); ++i) {
        if(notes.getJSONObject(i).getJSONArray("beat").getInt(0) == 0 && notes.getJSONObject(i).getJSONArray("beat").getInt(1) == 0) continue;

        //println(notes.getJSONObject(i).getInt("column"));
        //println(notes.getJSONObject(i).getJSONArray("beat"));

        //ノーツの初期位置を列挙
        if (hidenotes.get(i) == 0) {
            notex.set(i, width * notes.getJSONObject(i).getInt("column") /4);
            notey.set(i, barlines.get(notes.getJSONObject(i).getJSONArray("beat").getInt(0)) - hispeed * (bpm * notes.getJSONObject(i).getJSONArray("beat").getInt(1) / notes.getJSONObject(i).getJSONArray("beat").getInt(2)));
        
            //ノーツ判定
            if (key1 && notes.getJSONObject(i).getInt("column") == 0) judgesort(i , "key1");
            if (key2 && notes.getJSONObject(i).getInt("column") == 1) judgesort(i , "key2");
            if (key3 && notes.getJSONObject(i).getInt("column") == 2) judgesort(i , "key3");
            if (key4 && notes.getJSONObject(i).getInt("column") == 3) judgesort(i , "key4");

        }

        //負荷軽減
        if (-100 < notey.get(i) + dy && notey.get(i) + dy < height + 100) {
            imageMode(CENTER);
            // 画像を指定したサイズ(64x64)で描画
            image(emoji, notex.get(i) + width / 8, notey.get(i) + dy, 64, 64);
        }

    }

    //println(notex);
    //println(notey);
    //println(notey.get(0) + dy);

    //譜面スクロール
    //player.position() で現在の再生時間（ミリ秒）を取得し、秒に変換
    float currentSec = player.position() / 1000.0;
    //経過時間から現在あるべきスクロール位置を絶対計算する
    dy = currentSec * (bpm * bpm / (rhythmbeat * 60.0)) * hispeed;

    //println(frameRate);

    //判定線
    strokeWeight(4);
    line(0, height * 4/5, width, height * 4/5);

    key1 = false;
    key2 = false;
    key3 = false;
    key4 = false;

    //リザルト画面
    if (notey.min() + dy > height) {
        fill(0, 0, 88);
        strokeWeight(1);
        square(width/10, height/10, width * 4/5);

        fill(255);
        textAlign(CENTER);
        textSize(16);
        text("RESULT", width/2, height * 2/10);

        textAlign(LEFT);
        textSize(32);
        text("best: " + bestcount.size(), width/5, height * 3/10);
        text("cool: " + (coolfastcount.size() + coollatecount.size()) + " (" + coolfastcount.size() + "/" + coollatecount.size() + ")", width/5, height * 4/10);
        text("good: " + (goodfastcount.size() + goodlatecount.size()) + " (" + goodfastcount.size() + "/" + goodlatecount.size() + ")", width/5, height * 5/10);
        text("miss: " + (notes.size() - bestcount.size() - coolfastcount.size() - coollatecount.size() - goodfastcount.size() - goodlatecount.size() - 1), width/5, height * 6/10);

        textAlign(CENTER);
        textSize(16);
        text("Backspaceを押して戻る", width/2, height * 8/10);
    }
}

//キー操作
void keyPressed() {
    if (key == 'd') key1 = true;
    if (key == 'f') key2 = true;
    if (key == 'j') key3 = true;
    if (key == 'k') key4 = true;

    //プレイ中（またはリザルト画面）で Backspace を押した時の処理
    if (Page == "Play" && key == BACKSPACE) {
        
        //1. 音楽を停止・クローズする
        if (player != null && player.isPlaying()) {
            player.pause();
            player.close();
        }

        //2. 譜面や判定のリストをすべてリセット (.clear() で一括消去できます)
        barbeats.clear();
        barlines.clear();
        notex.clear();
        notey.clear();
        hidenotes.clear();
        bestcount.clear();
        coolfastcount.clear();
        coollatecount.clear();
        goodfastcount.clear();
        goodlatecount.clear();
        misscount.clear();

        //3. 状態変数を初期化
        dy = 0;              // スクロール位置をリセット
        gamestart = false;   // Play画面に入ったときの読み込みを再度行わせる
        
        //4. ページを選曲画面に戻す
        Page = "Select";
    }
}

//ノーツ判定処理
void judgesort(int i, String keyn) {
    if (height * 4/5 - hispeed * judgegood < notey.get(i) + dy && notey.get(i) + dy < height * 4/5 + hispeed * judgegood) {         //good判定
        if(height * 4/5 - hispeed * judgecool < notey.get(i) + dy && notey.get(i) + dy < height * 4/5 + hispeed * judgecool) {      //cool判定
            if(height * 4/5 - hispeed * judgebest < notey.get(i) + dy && notey.get(i) + dy < height * 4/5 + hispeed * judgebest) {  //best判定
                judges(i, "best", keyn);                  //best判定
                bestcount.append(1);
            }else{

                if (notey.get(i) + dy < height * 4/5) {
                    judges(i, "cool(fast)", keyn);        //cool(fast)判定
                    coolfastcount.append(1);
                }else{

                    if (height * 4/5 < notey.get(i) + dy) {
                        judges(i, "cool(late)", keyn);    //cool(late)判定
                        coollatecount.append(1);
                    }
                }
            }
        }else{

            if (notey.get(i) + dy < height * 4/5) {
                judges(i, "good(fast)", keyn);            //good(fast)判定
                goodfastcount.append(1);
            }else{
                
                if (height * 4/5 < notey.get(i) + dy) {
                    judges(i, "good(late)", keyn);        //good(late)判定
                    goodlatecount.append(1);
                }
            }
        }
    }
}

void judges(int i, String judge, String keyn) {
    hidenotes.set(i, 1);
    notey.set(i, 1000);
    println(judge);
    if (keyn == "key1") key1 = false;
    if (keyn == "key2") key2 = false;
    if (keyn == "key3") key3 = false;
    if (keyn == "key4") key4 = false;
}

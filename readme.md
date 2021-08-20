# MT4でEAを使えるようになるまでの練習

- MQL4で作れるものは3つ（https://book.mql4.com/basics/programms）
  - Expert Advisor（tickごとに動作する。自動売買を行う）
  - custom indicator（tickごとに動作する。自動売買は行わず、チャート上に線を表示するなどの処理を行う）
  - script（動作は一度のみ）

- [MT4でEAを使えるようになるまでの練習](#mt4でeaを使えるようになるまでの練習)
  - [MT4のインストール](#mt4のインストール)
  - [このリポジトリのダウンロード](#このリポジトリのダウンロード)
  - [開発への参加の仕方（Gitの使い方について）](#開発への参加の仕方gitの使い方について)
  - [プログラムを実行するまでの流れ](#プログラムを実行するまでの流れ)
  - [`Moving Average.mq4`の解読](#moving-averagemq4の解読)
    - [`MaximumRisk = 0.02`](#maximumrisk--002)
    - [poolと`OrderSelect()`関数について](#poolとorderselect関数について)
      - [pool](#pool)
      - [`OrderSelect`](#orderselect)
    - [`if (Volume[0] > 1) return;`](#if-volume0--1-return)
    - [英語](#英語)
  - [`Moving Average.mq4`の改造](#moving-averagemq4の改造)
  - [バッチテストの実行](#バッチテストの実行)

## MT4のインストール

参考のため、僕がMT4をインストールした手順を書いておきます。環境を合わせたいときはフォローしてください。

1. [XMTradingのホームページ](https://www.xmtrading.com/jp/)に行く
2. デモ口座を開設する
   1. **取引プラットフォームタイプ：MT4**
   2. 口座タイプ：Standard
   3. 口座の基本通貨：JPY
   4. あとはご自由に
3. メールが送られてくるので、承認する。ログインIDをメモしておく
4. [ここから](https://www.xmtrading.com/jp/platforms)プラットフォームに合わせたMT4をインストール
5. MT4を起動し、言語を英語にして再起動（日本語だと文字化けする。Windowsだと大丈夫かも）
6. 右下の「Invalid account」みたいなところから、ログインする
   1. server: **XMTrading-Demo 3**
   2. login ID: メモしたID
   3. password: デモ口座開設時に設定したもの


- MT4はもともとWindows向けのアプリケーションで、UNIX系OS（macOSやLinux）で使うためWineを用いている
  - WineはUNIX系OSでWindows向けのアプリケーションを動作させるためのソフトウェア
- Windowsの場合、`C:\\Program Files\XMTradeing MT4\MQL4\`にもろもろがあると思う
- macOSの場合、`/Applications/MetaTrader\ 4.app/Contents/SharedSupport/metatrader4/support/metatrader4/drive_c/Program\ Files/MetaTrader\ 4/MQL4/Experts/`にEAのサンプルコードなどがあった
- XMTradingのMT4をインストールすると、サンプルコードは`/Applications/XMTrading\ MT4.app/drive_c/Program\ Files\ \(x86\)/XMTrading\ MT4/MQL4/Experts/Moving\ Average.mq4`にあった

## このリポジトリのダウンロード

<div align="center">
    <img src="https://docs.github.com/assets/images/help/repository/code-button.png" width="500px">
</div>

ここから「Download ZIP」する。あるいは`git`コマンドが使えるならば

```bash
$ cd <where_you_want_to_download_this_repo>
$ git clone https://github.com/JoyBolte/mt4-practice.git
```

## 開発への参加の仕方（Gitの使い方について）

- Gitはバージョン管理のためのツールです
- 誰が、いつ、どのように編集したかが記録される

<div align="center">
    <img src="./figures/gennba-neko.jpeg" width="500px">
</div>

このようなことがなくなる。


**（Gitの使い方を書こうと思ったけど、大変になるのでやめた。もし自分の変更をここにmergeする方法を知りたいと思ったら声をかけてください）**



## プログラムを実行するまでの流れ

1. MetaEditorや普通のエディタで`.mq4`ファイルを作成
2. （MetaEditorで？）コンパイル→実行ファイル`.ex4`ができる
3. `.ex4`ファイルを然るべきフォルダ、ディレクトリにコピー
   1. Windows: `C:\\Program Files\MetaTrader 4 at FOREX.com\experts\`など
   2. macOS: `/Applications/MetaTrader\ 4.app/Contents/SharedSupport/metatrader4/support/metatrader4/drive_c/Program\ Files/MetaTrader\ 4/MQL4/`配下
      1. `Scripts/`, `Indicators/`, `Experts/`
   3. たぶんパス名はバージョンなどによっても異なる
4. Strategy Testerという機能を使って**バックテスト**をする
5. 自動売買を実行

## `Moving Average.mq4`の解読

MT4にデフォルトでついてくるサンプルコード`Moving Average.mq4`を読解する。

基本的に`src/ma.mq4`に写経しながら読解をする（内容は同じ）。説明はコメントで残すようにした。

しかしコメントで載せきれないような重要なポイントはここに書こうと思う。

### `MaximumRisk = 0.02`
- リスクマネジメントのためのrisk rate.
- 一般的に、資金の2%の損失が出たらロスカットをすべきらしい。
- アグレッシブだと2%で、慎重にトレードするならば1%とかにする。
- とにかく**損切りは2%以下でやるべし**
- https://toushi-strategy.com/fx/money-management/

### poolと`OrderSelect()`関数について

#### pool

- `OrderSelect()`関数について調べているときに出会った概念
- ここの説明がわかりやすい：[MQL4のOrderSelect関数を正しく理解する - Qiita](https://qiita.com/bucchi49/items/be71179f8b5c09b11e23)
- **オーダーの履歴的なものを、MT4ではpool**と呼んでいるらしい。
- poolには2種類あって、trading poolとhistory pool.
  - **trading pool**: 保持中のポジションや、予約待ちのポジションの情報
  - **history pool**: クローズしたポジションや、予約をキャンセルしたオーダーの履歴
- trading poolとhistory poolを合わせて**order pool**と呼ぶ

- trading poolとhistory poolはそれぞれ注文に**index**を持っている
  - indexはオーダーの順番に0, 1, 2, ...となる
  - 例えばtrading poolのindex = 2のオーダーを決済したとすると、それはtrading poolから消えて、index = 3がindex = 2になる。同様にindex = nはindex = n-1になる（n >= 3）
  - 決済したオーダーはhistory poolに追加される。history poolにm個のオーダーが詰まっていた（index = 0からindex = m-1まで）とすると、index = mに決済したオーダーの履歴が追加される

#### `OrderSelect`

- [ドキュメント](https://docs.mql4.com/trading/orderselect)

```c
bool  OrderSelect(
   int     index,            // index or order ticket
   int     select,           // flag
   int     pool=MODE_TRADES  // mode
   );
```

- オーダーの選択をする
  - `index`
  - `select`：`SELECT_BY_POS`とすることでorder poolのindexを使用する
  - `pool`: `MODE_TRADES`ならばtrading pool, `MODE_HISTORY`ならhistory poolから選択する
  - 引数の詳細は[ドキュメント](https://docs.mql4.com/trading/orderselect)をみてください
- オーダーの選択に成功した場合はtrue、失敗した場合はfalseを返す
> OrderSelect関数でオーダーを選択すると、OrderMagicNumberやOrderOpenPriceなどの関数を使用してオーダーの詳細情報を取得できるようになります。


- `Moving Average.mq4`の`CalculateCurrentOrders(string symbol)`内では、trading poolのorderを`for`文でスキャンしていって、`OrderSelect(i, SELECT_BY_POS, MODE_TRADES)`で取得できなくなったらその`for`を抜けるようにしているらしい
- これでオーダーを「選択」しておくことで、次の`OrderSymbol()`などの関数が使えるようになる

### `if (Volume[0] > 1) return;`

1本のbarにつき1度だけEAを起動させるようなことがしたい。そのようなときに`if (Volume[0] > 1) return;`とするといいらしい。

`Volume[0]`には現在のティックの出来高が格納されている。これが1より大きいということは、現在のティックは新しい足が生成されてから、最新のティックではないということを意味しているので、`return`で関数を終了している。

しかし新しいtickでも`Volume[0]`は1より大きい数字で始まることがあるらしい。より完全なロジックや詳しくは以下のブログを参照するといい。

- https://autofx100.com/2019/10/25/%EF%BC%91%E6%9C%AC%E3%81%AE%E8%B6%B3%E3%81%A7%EF%BC%91%E5%9B%9E%E3%81%A0%E3%81%91%E4%BB%95%E6%8E%9B%E3%81%91%E3%82%8B%E6%A9%9F%E8%83%BD-%E6%9C%80%E7%B5%82%E7%89%88/
- https://autofx100.com/2015/02/20/%ef%bc%91%e6%9c%ac%e3%81%ae%e8%b6%b3%e3%81%a7%ef%bc%91%e5%9b%9e%e3%81%a0%e3%81%91%e4%bb%95%e6%8e%9b%e3%81%91%e3%82%8b%e6%a9%9f%e8%83%bd/
- https://autofx100.com/2017/03/01/%ef%bc%91%e6%9c%ac%e3%81%ae%e8%b6%b3%e3%81%a7%ef%bc%91%e5%9b%9e%e3%81%a0%e3%81%91%e4%bb%95%e6%8e%9b%e3%81%91%e3%82%8b%e6%a9%9f%e8%83%bd-%e6%94%b9%e5%96%84%e7%89%88/


### 英語

- symbol: 通貨ペア（'usdjpy', 'eurjpy', ...）
- timeframe: 時間軸（時間足とか日足とかのこと）
- limit order: 指値注文
- stop order: 逆指値注文
- market order, order without limit: 成行注文
- consecutive losing trades: 連続した負けトレード
- free margin: 余剰証拠金

## `Moving Average.mq4`の改造

- `ma.mq4`を改造してみたものを`my_ma.mq4`とした
- （ただ`Lots`とかの変数を使わないようにしただけ）
- XMTrading MT4を使っているので、そこにシンボリックリンクを貼った

```bash
$ cd /Applications/XMTrading\ MT4.app/drive_c/Program\ Files\ \(x86\)/XMTrading\ MT4/MQL4/Experts/
$ ln -s <path_to>/my_ma.mq4 my_ma.mq4
$ ls -AltrhFs
total 96
-rwxrwxrwx  1 root     admin   6.1K  8 19 15:33 MACD Sample.mq4*
-rwxrwxrwx  1 root     admin   5.0K  8 19 15:33 Moving Average.mq4*
-rw-r--r--  1 okazaki  admin    10K  8 19 15:33 MACD Sample.ex4
-rw-r--r--  1 okazaki  admin    15K  8 19 15:33 Moving Average.ex4
-rwxrwxrwx  1 root     admin   3.1K  8 19 16:26 mqlcache.dat*
lrwxr-xr-x  1 okazaki  admin    46B  8 19 16:46 my_ma.mq4@ -> <path_to>/my_ma.mq4
```

## バッチテストの実行

- やり方：https://www.forex.com/~/media/forex/files/services/metatrader/mt4-manuals/howtousemetatrader4-20190222-1.pdf
- 10,000 USDとかでやらないと`OrderSend error 134`になる…（余剰証拠金が足りないということ）
- `my_ma.mq4`は期間や時間足などによってprofitがプラスになったりマイナスになったり、安定しない
- ポジションをクローズしたら逆のポジションを持つようにしたらどうか？

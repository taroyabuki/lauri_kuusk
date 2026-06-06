# ラウリの КУВТ

> これが『ラウリの КУВТ』だ。<br>子供向けに大きな字で書かれたそれは、ミニゲームのサンプルを挟みながら、プログラミングの概念をわかりやすく伝えるものとなっていた。（雑誌 p.26、文庫 p.53）

AI に、宮内悠介『ラウリ・クースクを探して』から、『ラウリの КУВТ』のミニゲームのサンプルになりそうなものを抽出、実装させました。うまく行っていないものもありますが、雰囲気を知る手がかりにはなるでしょう。

- **雑誌**：『小説 TRIPPER』2023年夏季号
- **単行本**：朝日新聞出版（2023）
- **文庫**：朝日新聞出版（2026）

うまく行かない理由として考えられること：

- プロンプトが悪い。「コンピュータに関する話題を抽出して」で抽出、「MSX2 用に実装できるものを、その番号のフォルダで実装して」で実装させた。
- 個別実装だから、ラウリたちの成長に対応していない。（後で発見するテクニックは前では使えないはず。）
- 引用部分とは別のところに書かれた情報を考慮していない。
- MSX のテクニックがロストテクノロジーになっている。（AI が MSX のテクニックに詳しくない。）

## 100. TRS-80

> ラウリの転機&mdash;いま見るならば、必ずしも幸福な転機とは言えないかもしれないそれは、五歳の春に訪れた。父が勤め先の工場から壊れた TRS-80 コンピュータ、当時のソビエトの言葉で言う電子計算機を持ち帰ったのだ。（雑誌 p.11、文庫 p.18）

<a title="Flominator, CC BY-SA 3.0 &lt;https://creativecommons.org/licenses/by-sa/3.0&gt;, via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:TRS-80_Model_I_-_Rechnermuseum_Cropped.jpg"><img width="250" alt="TRS-80 Model I - Rechnermuseum Cropped" src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/TRS-80_Model_I_-_Rechnermuseum_Cropped.jpg/250px-TRS-80_Model_I_-_Rechnermuseum_Cropped.jpg"></a>

## 110. 雪の粒が舞い散る小さなデモ

> 画面に雪の粒が舞い散る小さなデモだ。（中略）<br>一色しか表示できないので、黒地に白だけ。グラフィックが表示できないから、文字一つぶんの白い四角形を雪の粒に見立てる。（雑誌 p.12、文庫 p.20）

[▶️実行](https://msxpen.com/?gist=ba2582bc6ffac7892c15fca0ffa217c7)


## 120. 足し算

> 「では簡単なプログラムを作ってみようか」<br>先生がそう言って、皆がプログラムを組むことになった。アーロンが足し算のプログラムを作って先生に褒められているのが見える。（雑誌 p.17、文庫 p.32）

[▶️実行](https://msxpen.com/?gist=61c266ca746294a2446eec2a097b03e2)


## 130. 竜のゲーム

> それを横目に、ラウリは竜のゲームを作った。<br>“*”の字を並べた竜が画面を降りていき、障害物の炎を避けるゲームだ。（雑誌 p.17、文庫 p.32）

[▶️実行](https://msxpen.com/?gist=0bc24995e2c707323d91e50fcafd6926)


## 140. 車のゲーム

> まもなく車のゲームができあがった。車を左右に操作して、別の車にぶつかったらゲームオーバー。すぐに完成させたかったので、道は直線のみ。でも、充分に(ゲーム|遊べるもの)になっていた。（雑誌 p.17、文庫 p.33）

[▶️実行](https://msxpen.com/?gist=ab6e432c3760bce3250ffb30ea83c0bf)


## 150. КУВТ (KUVT)

> ラウリの触れた生徒用のКУВТはヤマハのYIS-503IIIRである。CPU は Z80、メモリが一二八キロバイト、ビデオメモリが一二八キロバイトであった。テープなどの補助記憶装置はなく、データを保存する際は、簡易ネットワークを介して教師用のマシンでメディアに保存された。（雑誌 p.18、文庫 p.36）

- [Yamaha YIS-503IIIR (MSX Resource Center)](https://www.msx.org/wiki/Yamaha_YIS-503IIIR)
- [サイボーグMSX「魔改造されたソ連MSX・16台LAN接続可能YAMAHA KUVT」](https://note.com/cyborgmsx/n/n7e9e367534ae)
- [YAMAHA KUVT (Wikipedia)](https://ja.wikipedia.org/wiki/YAMAHA_KUVT)

<a title="Bushido Senshi, CC BY 4.0 &lt;https://creativecommons.org/licenses/by/4.0&gt;, via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:Yamaha_KUVT2_(cropped).jpg"><img width="330" alt="Yamaha KUVT2 (cropped)" src="https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/Yamaha_KUVT2_%28cropped%29.jpg/330px-Yamaha_KUVT2_%28cropped%29.jpg"></a>

## 160. 列車はブルジバールへ

> 教育映画の『列車はブルジバールヘ』では、子供たちが楽しそうに MSX のゲーム、『(イーアルカンフー|イー・アル・カンフー)』や『サーカスチャーリー』で遊ぶ姿が収められている。（雑誌 p.19、文庫 p.36）

- [『列車はブルジバールヘ』の該当箇所（YouTube）](https://youtu.be/jxcUORtftgo?si=n-CqQa-XKzkMAejD&t=2649)
- [file-hunter Yie Ar Kung-Fu イーアルカンフー SCC Version by Konami を検索](https://search.brave.com/search?q=file-hunter+Yie+Ar+Kung-Fu+%E3%82%A4%E3%83%BC%E3%82%A2%E3%83%AB%E3%82%AB%E3%83%B3%E3%83%95%E3%83%BC+SCC+Version+by+Konami)
- [file-hunter Circus Charlie サーカスチャーリー by Konami を検索](https://search.brave.com/search?q=file-hunter+Circus+Charlie+%E3%82%B5%E3%83%BC%E3%82%AB%E3%82%B9%E3%83%81%E3%83%A3%E3%83%BC%E3%83%AA%E3%83%BC+by+Konami)

## 170. 『MSX コンプリート・プログラミングリファレンスガイド』

> このとき、ライライは一つ忘れられない贈りものをラウリのために用意していた。イギリスで出版された『MSX コンプリート・(プログラミング|プログラミング・)リファレンスガイド』を彼女がロシア語に抄訳したものだ。（雑誌 p.20、文庫 p.40）

原書は [The Complete MSX Programmers Guide (Internet Archive)](https://archive.org/details/TheCompleteMSXProgrammersGuide) か？　[The Msx, Complete Programming Reference Guide (Open Library)](https://openlibrary.org/books/OL11665039M/The_Msx_Complete) と ISBN は同じである。

<a href="https://archive.org/details/TheCompleteMSXProgrammersGuide"><img src="https://archive.org/download/TheCompleteMSXProgrammersGuide/The%20Complete%20MSX%20Programmers%20Guide_jp2.zip/The%20Complete%20MSX%20Programmers%20Guide_jp2%2FThe%20Complete%20MSX%20Programmers%20Guide_0000.jp2&ext=jpg" alt="The Complete MSX Programmers Guide" style="width:400px;"></a>

## 180. 芋虫ゲーム

> このころラウリの作ったゲームに、芋虫となって枝の上で暮らすというものがある。<br>葉っぱを食べれば得点になり、鳥に見つかればゲームオーバー。（雑誌 p.21、文庫 p.41）

[▶️実行](https://msxpen.com/?gist=4d2490aaf263baaf15b4faffaa0d0de9)


## 190. 鉄くず集め

> この時期に作られたラウリのゲームに『鉄くず集め』がある。<br>主人公はピオネールの一員となり、白いシャツに赤いネッカチーフ、赤い帽子、半ズボンという出で立ちで奉仕活動の鉄くず集めをする。たくさん鉄くずが集まれば、高得点というわけだ。（雑誌 p.23、文庫 p.47）

[▶️実行](https://msxpen.com/?gist=7dadc082ee527b7d1aeca9235b3bd897)


## 200. 氷作り

> このころラウリが作った小品に『氷作り』がある。КУВТのグラフィックモードを使用した作で、中身は、製氷皿をうまく動かして氷を作るというだけ。四、五分も(あ|や)れば飽きてしまう代物だが、身の回りのものすべてをプログラムに落としこもうというラウリの発想が垣間見える。（雑誌 p.25、文庫 p.51）

[▶️実行](https://msxpen.com/?gist=c637f92dfa0eebbb5f83936b3063b40a)


## 210. マルス3号の火星着陸

> イヴァンの一等入選作はいわゆるシューティングゲームで、ホルゲル先生はすでにそのプログラムを取り寄せていた。（中略）<br>ゲームが扱うのはマルス3号の火星着陸。（雑誌 p.26、文庫 p.54）

[▶️実行](https://msxpen.com/?gist=7e98314f1cd3cddcbb0391990dc0d30f)


## 220. 想像のロケット

> 地球(を指し|に棒を突き立)て、線を引いて想像のロケットを飛ばす。<br>ロケットはそれぞれの天体の重力で、微妙に蛇行する。（雑誌 p.31、文庫 p.65）

[▶️実行](https://msxpen.com/?gist=4d3db4787f413583ef7726ae34fe0944)


## 230. 花火

> 最初の情報科学の時間なので、イヴァンと示しあわせて、それぞれちょっとした映像作品を作った。<br>ラウリは花火のデモ。（雑誌 p.35、文庫 p.76）

[▶️実行](https://msxpen.com/?gist=4e690783240c6c6b35490062f5636688)


## 240. 降りしきる雪のデモ

> 対して、イヴァンが降りしきる雪のデモだ。（雑誌 p.35、文庫 p.76）

[▶️実行](https://msxpen.com/?gist=31b3e378cd342e4fb25850dc5b029ecf)


## 250. 重力

> ラウリの作、『重力』は横スクロールシューティング風の外見。狭い画面のなか、大量の敵の弾と光線が行き来する、その弾や光線をかいくぐるゲームだ。<br>主人公は弾を撃つことができず、かわりに重力を操作する。周囲に重力を発生させると、敵の弾が引き寄せられるかわりに、光線を曲げて回避することができる。（雑誌 p.37、文庫 p.81）

[▶️実行](https://msxpen.com/?gist=8a7ace6356407768ad65c8ad7981f63d)


## 260. スムーズスクロール

> イヴァンの作は自動車のレースゲーム。（中略）<br>が、この作の試みは、ゲームとは別のところにあった。<br>イヴァンの試みはスムーズスクロール。（雑誌 p.38、文庫 p.81）

[▶️実行](https://msxpen.com/?gist=b1f39843ce8835c2111de026a548c64c)


## 270. 3Dのレースゲーム

> 今度こそイヴァンに勝つつもりでラウリが開発したのは、3Dのレースゲームだ。（雑誌 p.39、文庫 p.84）

[▶️実行](https://msxpen.com/?gist=4d02d4d610b642ff67b79579ea4be1fc)


## 280. 自前の乗算ルーチン

> 簡単に言うと、$ab=((a+b)^2-(a-b)^2)/4$ であることを利用し、あらかじめ(二乗|各数値の二乗)の計算結果を持っておく。この計算結果のテーブルが、一キロバイトほど。このように小さなテーブルを持つだけで、高速な乗算ができるというわけだ。（雑誌 p.39、文庫 p.85）

[▶️実行](https://msxpen.com/?gist=5632e37dfa75d43e169913b77e7014fe)


## 290. 素数

> (いつの間にか|すでに)単なプログラムはできるようになっていて、このとき彼女が投じたのは、素数を数えあげるプログラムだった。（雑誌 p.39、文庫 p.85）

[▶️実行](https://msxpen.com/?gist=b48ecc80041d0312ef35cbdd2d539d4e)


## 300. 歌うコンピュータ

> イヴァンが作ったのは、歌うコンピュータだった。<br>三音の電子音しか嗚らせないКУВТを、人間のように歌わせようというのだ。（雑誌 p.39、文庫 p.86）

[▶️実行](https://msxpen.com/?gist=eba11f85856acf141578ce7372029b25)


## 310. マルス3号の火星着陸・改

> シューティングゲームで、売りはイヴァン得意の滑らかな横スクロールだった。（中略）この年のイヴァンの作が、失格と(なっ|判定され)たのだ。理由は、ゲームの自機のデザインが、エストニアの三色旗を彷彿とさせる色あいになっていたこと。（雑誌 p.46、文庫 p.100）

[▶️実行](https://msxpen.com/?gist=9ba99a87155b48cb8b952b138023aa26)


## 320. 回転

> 対してラウリが作ったのが、『回転』というレースゲーム。回転機能のないКУВТで、ダイナミックに画面全体(が|を)回転(する|させる)ものだ。（雑誌 p.46、文庫 p.100）

[▶️実行](https://msxpen.com/?gist=d52fc6a7060d1bb9f1b774358fadb1db)


## 330. 宇宙戦艦のゲーム

> このときイヴァンが作りはじめたのは、宇宙戦艦のゲームだった。<br>黒地の背景に、異なる二つの速度で流れる星空。そして、滑らかにドット単位で動く灰色の巨大戦艦。得意のスクロール処理もさることながら、ラウリが気に入ったのは星空の演出だった。（雑誌 p.47、文庫 p.104）

[▶️実行](https://msxpen.com/?gist=4eb7a00f046d719616a0c2245d1f49db)


## 340. 立体的に表示される地下迷宮

> 対して、ラウリが作りはじめたのは立体的に表示される地下迷宮。<br>立体表示機能を持たないКУВТでで立体表現をやろうという点では、前に作ったものと同じだが、今回は本格的に光線追跡法（レイトレーシング）を取り入れた。これは、光線を追跡することで、像を正しくシミュレートしようというものだ。（雑誌 p.47、文庫 p.104）

[▶️実行](https://msxpen.com/?gist=8a7ea2a406cbc62003fe9e05e36585e5)

## 350. 水晶の国

> 三人のキャラクターを操り、湖畔で水晶を集める小さなパズルゲームだ。（雑誌 p.49、文庫 p.107）

[▶️実行](https://msxpen.com/?gist=5326809389f3f84e8da5394aac491cae)

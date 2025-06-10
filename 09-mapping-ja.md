# (PART) 拡張機能 {- #extensions}

# R で地図を作成  {#adv-map}



## 必須パッケージ  {- #prerequisites-09}

- この章では、すでに使用している以下のパッケージが必要である。


``` r
library(sf)
library(terra)
library(dplyr)
library(spData)
library(spDataLarge)
```

- 本章での主要なパッケージは **tmap** である。
CRAN よりも頻繁に更新されている [r-universe](https://r-universe.dev/) 版をお勧めする。訳註: macOS では、**tmap** は文字化けすることがある。[macOS で ragg を使用することで文字化けが解消する](https://uribo.hatenablog.com/entry/2021/03/29/202756)。


``` r
install.packages("tmap", repos = c("https://r-tmap.r-universe.dev",
                                   "https://cloud.r-project.org"))
```

- 以下の可視化に関するパッケージを使用する (動的な地図アプリを開発したい場合は、**shiny** もインストールしよう)。


``` r
library(tmap)    # 静的地図と動的地図
library(leaflet) # 動的地図
library(ggplot2) # tidyverse データ可視化パッケージ
```

- Section \@ref(spatial-ras) で紹介した二つのデータセットを読み込む必要がある。


``` r
nz_elev = rast(system.file("raster/nz_elev.tif", package = "spDataLarge"))
```

## イントロダクション  {#introduction-09}

地理学的研究は、その結果を伝えることで満足度と重要性が高まる。
地図作成あるいは地図学は、コミュニケーションと細部への注意、そして創造力を必要とする古来の技術である。\index{ちずせいさく@地図作成}
R における静的地図は、Section \@ref(basic-map) で見たように、`plot()` 関数を使えば簡単にできる。
R の基本メソッドを使って高度な地図を作成することも可能ではある [@murrell_r_2016]。
しかし、この章の焦点は、地図作成専用のパッケージを使った地図作成にある。
新しいスキルを身につけるには、1 つの分野の知識を深めてから手を広げていくことが大切である。
地図の作成も例外ではない。そのため、この章では多くのパッケージを表面的にではなく、1 つのパッケージ (**tmap**) を深く掘り下げて説明する。

地図作成は、楽しくてクリエイティブなだけでなく、実用的にも重要な役割を担っている。
丁寧に作られた地図は、仕事の成果を伝えるのに最適な方法であるが、デザインの悪い地図は印象を悪くすることがある。
よくあるデザイン上の問題点としては、*Journal of Maps* の[スタイルガイド](https://files.taylorandfrancis.com/TJOM-suppmaterial-quick-guide.pdf)で説明されているように、文字の配置やサイズ、読みにくさ、色の選び方の不注意などが挙げられる。
さらに、地図作りが不十分だと、結果の伝達にも支障が生じることがある [@brewer_designing_2015]。

> 素人が作ったような地図では、情報の重要性が伝わらず、専門家によるデータ調査をうまく表現できないことがある。
地図は数千年前からさまざまな用途に使われてきた。
歴史的な例としては、3000年以上前の古バビロニア王朝の建物や土地所有の地図、約2000年前のプトレマイオスの代表作<u>地理学</u>の世界地図などがある [@talbert_ancient_2014]。\index{ちりがく@地理学}

地図は、歴史的にエリートが自分のために作るか、あるいはエリートのために誰かが作る行為であった。
しかし、R パッケージの **tmap** や QGIS\index{QGIS} の印刷レイアウトのようなオープンソースの地図作成ソフトが登場し、誰でも高品質の地図を作ることができるようになり、「市民科学」が可能になったことで、状況は一変した。
また、ジオコンピュテーションの研究成果をわかりやすく紹介するためには、地図が最適な方法であることが多い。
したがって、地図作成はジオコンピュテーション\index{じおこんぴゅてーしょん@ジオコンピュテーション}の重要な一部であり、世界を記述するだけでなく、世界を<u>変えること</u>にも重点を置いているのである。

この章では、さまざまな地図の作り方を紹介する。
次のセクションでは、美観への配慮、ファセット、差し込み地図 (inset map) など、さまざまな静的地図について説明する。
また、Section \@ref(animated-maps) から Section \@ref(mapping-applications) では、アニメーションやインタラクティブな地図 (Web 地図や地図アプリケーションを含む) を紹介している。
最後に、Section \@ref(other-mapping-packages) は、**ggplot2** や **cartogram** など他の地図作成用パッケージを紹介する。

## 静的地図  {#static-maps}

\index{ちずさくせい@地図作成!せいてきちず@静的地図}
ジオコンピュテーションの視覚的な出力として最も一般的なのが静的地図であろう。
標準的なフォーマットとしては、ラスタ出力用に `.png`、ベクタ出力用に `.pdf` がよく用いられる。
当初、R が作成できる地図の種類は静的地図だけだった。
**sp** [@pebesma_classes_2005 参照] のリリースで状況が進展し、その後、地図作成のための多くの技術、関数、パッケージが開発された。
しかし、インタラクティブ地図がどんどん発明されてきたにもかかわらず、10 年経っても R では依然として静的なプロットが地理データの可視化の重点となっていた [@cheshire_spatial_2015]。

ジェネリック関数の `plot()` 関数は、ベクタやラスタの空間オブジェクトから静的地図を作成する最速の方法であることが多い (Section \@ref(basic-map) と Section \@ref(basic-map-raster) の項を参照)。
特にプロジェクトの開発段階では、シンプルさとスピードが優先され、`plot()` はこの点で優れている。
Base R のアプローチは拡張可能で、`plot()` は何十もの引数を提供している。
また、@murrell_r_2016 の Chapter  [14](https://www.stat.auckland.ac.nz/~paul/RG2e/chapter14.html) に示されているように、静的地図の低レベル制御を可能にする **grid** パッケージもアプローチの 1 つである。
この章では、**tmap** に焦点を当て、重要な美観とレイアウトのオプションに重点を置いている。

\index{tmap (package)}
**tmap** は強力で柔軟な地図作成パッケージで、賢明なデフォルトが設定されている。
簡潔な構文で、**ggplot2** のユーザには馴染みのある最小限のコードで魅力的な地図を作成することができる。
また、`tmap_mode()` を介して、同じコードで静的な地図とインタラクティブな地図を生成するユニークな機能を備えている。
最後に、(**sf** オブジェクトと **terra** オブジェクトを含む) 空間クラスを受け入れることができる点では、**ggplot2** などよりも優れている。

### tmap の基礎知識  {#tmap-basics}

\index{tmap (package)!きそ@基礎}
**ggplot2**と同様に、**tmap** は「グラフィックの文法」という考えに基づいている [@wilkinson_grammar_2005]。
各入力データセットは、地図上の位置 (データの `geometry` で定義)、色、その他の視覚的変数など、さまざまな方法で「地図作成」することができる。
基本的な構成要素は `tm_shape()` (入力データ、ベクタまたはラスタのオブジェクトを定義する) で、その後に `tm_fill()` や `tm_dots()` などの 1 つまたは複数のレイヤ要素が続く。
以下のチャンクは、このようなレイヤ構成を示し、Figure \@ref(fig:tmshape) の地図を生成する。


``` r
# nz shape に塗りつぶしレイヤを追加
tm_shape(nz) +
  tm_fill() 
# nz shape に境界レイヤを追加
tm_shape(nz) +
  tm_borders() 
# nz shape に塗りつぶしと境界レイヤを追加
tm_shape(nz) +
  tm_fill() +
  tm_borders() 
```

<div class="figure" style="text-align: center">
<img src="figures/tmshape-1.png" alt="New Zealand の形状を **tmap** 関数で塗りつぶし (左)、境界 (中)、塗りつぶしと境界 (右) のレイヤを追加してプロット。" width="100%" />
<p class="caption">(\#fig:tmshape)New Zealand の形状を **tmap** 関数で塗りつぶし (左)、境界 (中)、塗りつぶしと境界 (右) のレイヤを追加してプロット。</p>
</div>

この場合、`tm_shape()` に渡されるオブジェクトは `nz` で、New Zealand の地域を表す `sf` オブジェクトである (`sf` オブジェクトについては Section \@ref(intro-sf) を参照)。
`nz` を視覚的に表現するためにレイヤを追加し、`tm_fill()` と `tm_borders()` でそれぞれ Figure \@ref(fig:tmshape) の陰影部分 (左図) と枠線 (中図) を作成している。

\index{ちずさくせい@地図作成!れいや@レイヤ}
これは、直感的な地図作りの手法である。
新しいレイヤを<u>追加する</u>一般的なタスクは、追加演算子 `+` とそれに続く `tm_*()` によって引き受けられる。
アスタリスク(\*)は、以下のように名前から明らかなレイヤを指す。

- `tm_fill()`: (複合) ポリゴンの塗りつぶし
- `tm_borders()`: (複合) ポリゴンの境界線
- `tm_polygons()`: (複合) ポリゴンの塗りつぶしと境界線
- `tm_lines()`: (複合) 線の線
- `tm_symbols()`: (複合) 点、(複合) 線、(複合) ポリゴンのシンボル
- `tm_raster()`: ラスタデータの色付きのセル (３レイヤのあるラスタには `tm_rgb()` もある)
- `tm_text()`: (複合) 点、(複合) 線、(複合) ポリゴンのテキスト

Figure \@ref(fig:tmshape) の右側のパネルでは、塗りつぶし (fill) レイヤ<u>の上に</u>境界 (borders) を重ねた結果を示している。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">`qtm()` (**q**uick **t**hematic **m**aps) は、主題図を簡単に作成する関数である。
簡潔で、多くの場合、良いデフォルトの可視化を提供する。
例えば、`qtm(nz)` は `tm_shape(nz) + tm_fill() + tm_borders()` と全く同じである。
さらに、レイヤ追加も `qtm()` では `qtm(nz) + qtm(nz_height)` と簡単である。
欠点としては、美観をコントロールすることが難しい点がある。このため、この Chapter では解説しない。</div>\EndKnitrBlock{rmdnote}

### 地図オブジェクト  {#map-obj}

**tmap** の便利な点は、地図を表す<u>オブジェクト</u>を格納できることである。
以下のコードは、Figure \@ref(fig:tmshape) の最後のプロットをクラス `tmap` のオブジェクトとして保存することでこれを示している (`tm_polygons()` 関数は、`tm_fill() + tm_borders()` を単一の関数に凝縮したもの)。


``` r
map_nz = tm_shape(nz) + tm_polygons()
class(map_nz)
#> [1] "tmap"
```

`map_nz` は後でプロットすることができる。例えば、レイヤを追加したり (下図参照)、コンソールで `map_nz` を実行するだけで、`print(map_nz)` と同じ意味になる。

新しい *shape* は、`+ tm_shape(new_obj)` で追加することができる。
この場合、`new_obj` は、先行するレイヤの上にプロットされる新しい空間オブジェクトを表す。
このようにして新しい形状が追加されると、次の新しい形状が追加されるまで、それ以降のすべての美観機能はその形状を参照する。
この構文により、複数の形状やレイヤを持つ地図を作成することができる。次のコードでは、関数 `tm_raster()` を使ってラスタレイヤ (レイヤを半透明にするために `col_alpha` を設定している) を描画している様子を示している。


``` r
map_nz1 = map_nz +
  tm_shape(nz_elev) + tm_raster(col_alpha = 0.7)
```

先に作成した `map_nz` オブジェクトをベースに、新しい地図オブジェクト `map_nz1` を作成する。このオブジェクトには、New Zealand 全土の平均標高を表す別の図形 (`nz_elev`) が含まれている (Figure \@ref(fig:tmlayers) 左図)。
さらに図形やレイヤを追加することもできる。以下のコードでは、New Zealand の[領海](https://en.wikipedia.org/wiki/Territorial_waters)を表す `nz_water` を作成し、作成した線を既存の地図オブジェクトに追加している。


``` r
nz_water = st_union(nz) |>
  st_buffer(22200) |> 
  st_cast(to = "LINESTRING")
map_nz2 = map_nz1 +
  tm_shape(nz_water) + tm_lines()
```

`tmap` オブジェクトに追加できるレイヤやシェイプの数に制限はない。同じシェイプを複数回使用することも可能である。
Figure \@ref(fig:tmlayers) に示される最終的な地図は、先に作成された `map_nz2` オブジェクトに `tm_dots()` で高ポイントを表すレイヤ (オブジェクト `nz_height` に格納) を追加して作成される (**tmap** のポイントプロット機能の詳細については `?tm_dots` と `?tm_bubbles` を参照)。
その結果、4つのレイヤを持つ地図ができあがり、Figure \@ref(fig:tmlayers) の右側のパネルに示されている。


``` r
map_nz3 = map_nz2 +
  tm_shape(nz_height) + tm_symbols()
```

\index{ちずさくせい@地図作成!めたぷろっと@メタプロット}
便利だがあまり知られていない **tmap** の機能として、`tmap_arrange()` がある。これは、複数の地図オブジェクトを一つの「メタプロット」に配置することができる。
Figure \@ref(fig:tmlayers)は、`map_nz1` から `map_nz3` までをメタプロットしている例である。


``` r
tmap_arrange(map_nz1, map_nz2, map_nz3)
```

<div class="figure" style="text-align: center">
<img src="figures/tmlayers-1.png" alt="Figure 9.1 の最終地図にレイヤを追加した地図。" width="100%" />
<p class="caption">(\#fig:tmlayers)Figure 9.1 の最終地図にレイヤを追加した地図。</p>
</div>

また、`+` 演算子でさらに要素を追加することができる。
ただし、美観の設定は、レイヤ関数の引数で制御する。

### 可視化の変数  {#visual-variables}

\index{ちずさくせい@地図作成!びかん@美観}
\index{ちずさくせい@地図作成!かしかのへんすう@可視化の変数}
前節のプロットは、**tmap** のデフォルトの美観セッティングを示してきた。
`tm_fill()` と `tm_symbols()` のレイヤには灰色の影を使用し、`tm_lines()` で作成した線を表現するために、連続した黒い線を使用する。
もちろん、これらのデフォルト値やその他の美観は上書きすることができる。
このセクションでは、その方法を示していく。

地図の美観には、大きく分けて「データによって変化するもの」と「一定であるもの」がある。
**ggplot2** ではヘルパー関数 `aes()` を使って変数の美観を表現するが、**tmap** はレイヤの種別に応じた美観の引数を直接受け付ける。

- `fill`: ポリゴンの塗りつぶし色
- `col`: ポリゴン境界線、線、点、ラスタの色
- `lwd`: 線幅
- `lty`: 線種
- `size`: シンボルの大きさ
- `shape`: シンボルの形

さらに、塗りつぶしと線の色の透過率を `fill_alpha` and  `col_alpha` で指定することができる。

美観に変数に応じて変化させるには、対応する引数に列名を渡す。美観を固定するには、希望の値を渡す。^[
固定値と列名の間に衝突があった場合、列名が優先される。これは、`nz$red = 1:nrow(nz)` を実行した後に次のコードチャンクを実行することで確認できる。
]
固定値を設定した例を Figure \@ref(fig:tmstatic) に示す。


``` r
ma1 = tm_shape(nz) + tm_polygons(fill = "red")
ma2 = tm_shape(nz) + tm_polygons(fill = "red", alpha = 0.3)
ma3 = tm_shape(nz) + tm_polygons(col = "blue")
ma4 = tm_shape(nz) + tm_polygons(lwd = 3)
ma5 = tm_shape(nz) + tm_polygons(lty = 2)
ma6 = tm_shape(nz) + tm_polygons(fill = "red", fill_alpha = 0.3,
                                 col = "blue", lwd = 3, lty = 2)
tmap_arrange(ma1, ma2, ma3, ma4, ma5, ma6)
```

<div class="figure" style="text-align: center">
<img src="figures/tmstatic-1.png" alt="よく使われる塗りつぶしや枠線の美観を固定値に変更した場合の影響。" width="100%" />
<p class="caption">(\#fig:tmstatic)よく使われる塗りつぶしや枠線の美観を固定値に変更した場合の影響。</p>
</div>

Base R のプロットと同様に、美観を定義する引数もまた、様々な値を受け取ることができる。
ただし、Base R コード (Figure \@ref(fig:tmcol) の左のパネルを生成) とは異なり、**tmap** 美観引数は数値ベクトルを受け付けない。


``` r
plot(st_geometry(nz), col = nz$Land_area)  # 成功
tm_shape(nz) + tm_fill(fill = nz$Land_area) # 失敗
#> Error: palette should be a character value
```

`fill` (線レイヤの場合は `lwd`、点レイヤの場合は `size` など) は、プロットされるジオメトリに関連する属性を、数値ベクトルではなく文字列を渡す必要がある。
次のようにすると望ましい結果を得ることができる (Figure \@ref(fig:tmcol) 右図)。


``` r
tm_shape(nz) + tm_fill(fill = "Land_area")
```

<div class="figure" style="text-align: center">
<img src="figures/tmcol-1.png" alt="数値色フィールドの Base (左) と **tmap** (右) の処理方法の比較。" width="45%" /><img src="figures/tmcol-2.png" alt="数値色フィールドの Base (左) と **tmap** (右) の処理方法の比較。" width="45%" />
<p class="caption">(\#fig:tmcol)数値色フィールドの Base (左) と **tmap** (右) の処理方法の比較。</p>
</div>

視覚化の変数には、`.scale`、`.legend`、`.free` という文字列を後ろにつけた 3 つの追加引数がある。
例えば、`tm_fill()` には `fill`、`fill.scale`、`fill.legend`、`fill.free` といった引数がある。
`.scale` 引数は、地図と凡例での表示方法を指定し (Section \@ref(scales))、`.legend` はタイトル、方向、位置を指定する (Section \@ref(legends))。
`.free` 引数は、多くのファセットをもつ地図で、ファセットによってスケールや凡例が変わる場合などに使用する。

### スケール (scale)  {#scales}

\index{tmap (package)!すけーる@スケール}
ここでいうスケールとは、縮尺のことではなく、地図と凡例で値がどのように表示されるかを制御することである。
例えば、`col` という変数の場合、`col.scale` が空間オブジェクトの色が値にどう対応するかを制御する。`size` という変数の場合、`size.scale` は大きさが値にどう対応するかを制御する。
デフォルトでは、`tm_scale()` が使われ、入力データ種別 (因子型、数値型、整数型) によって自動的に設定を選択する。

\index{tmap (package)!いろわけ@色分け}
ポリゴンの塗りつぶしの設定によってスケールがどのように機能するか見てみよう。
カラー設定は、地図デザインの重要な要素である。Figure \@ref(fig:tmpal) に示すように、空間変動の描き方に大きな影響を与える可能性がある。
これは、New Zealand の地域を中央値によって色分けする 4 つの方法を、左から右に示している (下のコードチャンクでも示している)。

- デフォルトの設定では、次の段落で説明する 'pretty' 区切りが使用される
- `breaks` では、手動で区切りを設定することができる
- `n` は、数値変数を分類するビンの数を設定する
- `palette` は配色を定義するもので、例えば `BuGn` 


``` r
tm_shape(nz) + tm_polygons(fill = "Median_income")
tm_shape(nz) + tm_polygons(fill = "Median_income",
                           fill.scale = tm_scale(breaks = c(0, 30000, 40000, 50000)))
tm_shape(nz) + tm_polygons(fill = "Median_income",
                           fill.scale = tm_scale(n = 10))
tm_shape(nz) + tm_polygons(fill = "Median_income",
                           fill.scale = tm_scale(values = "BuGn"))
```

<div class="figure" style="text-align: center">
<img src="figures/tmpal-1.png" alt="色設定。結果は (左から) デフォルト設定、手動区切り、n 区切り、パレットを変更した場合の結果を示している。" width="100%" />
<p class="caption">(\#fig:tmpal)色設定。結果は (左から) デフォルト設定、手動区切り、n 区切り、パレットを変更した場合の結果を示している。</p>
</div>

\BeginKnitrBlock{rmdnote}<div class="rmdnote">上の引数 (`breaks`、`n`、`values`) は、他の視覚化変数でも機能する。
例えば、`values` は、`fill.scale` or `col.scale` に対しては色のベクトル、パレット名、`size.scale` に対しては大きさのベクトル、`shape.scale` に対してはシンボルのベクトルを期待する。</div>\EndKnitrBlock{rmdnote}

\index{tmap (package)!break}
`tm_scale_` から始まる関数ファミリーでスケールをカスタマイズすることもできる。
最も重要なものは、`tm_scale_intervals()`、`tm_scale_continuous()`、`tm_scale_categorical()` である。



\index{tmap (package)!interval}
`tm_scale_intervals()` 関数は、入力データ値を間隔セットに分割する。
`breaks` を手動で設定する代わりに、`style` 引数で **tmap** に自動的にブレイクを作成するアルゴリズムを選択することもできる。
デフォルトは `tm_scale_intervals(style = "pretty")` で、可能な限り整数に丸めて均等の間隔にする。
その他のオプションは、Figure \@ref(fig:break-styles) に示している。

- `style = "equal"`: 入力値を同じ範囲のビンに分割し、一様な分布を持つ変数に適している (結果の地図が色の多様性に乏しくなる可能性があるため、歪んだ分布を持つ変数には推奨されていない)。
- `style = "quantile"`: 同じ数の観測が各カテゴリに入ることを保証する (ビンの範囲が広く変化する可能性があるというマイナス面を含む)。
- `style = "jenks"`: データ中の類似した値のグループを識別し、カテゴリ間の差異を最大化する。
- `style = "log10_pretty"`: 右に裾が広がっている分布の変数に使われる、pretty スタイルの対数版 (底は 10)

\BeginKnitrBlock{rmdnote}<div class="rmdnote">`style` は **tmap** 関数の引数ではあるが、これはもともと `classInt::classIntervals()` の引数である。よって、詳細はこの関数のヘルプを参照。</div>\EndKnitrBlock{rmdnote}

<div class="figure" style="text-align: center">
<img src="figures/break-styles-1.png" alt="**tmap** の style 引数で設定するビン方法の違い。" width="100%" />
<p class="caption">(\#fig:break-styles)**tmap** の style 引数で設定するビン方法の違い。</p>
</div>

\index{tmap (package)!continuous}
`tm_scale_continuous()` 関数は、連続色フィールドの色を提示する。連続ラスタによく用いられる (Figure \@ref(fig:concat) 左図)。
分布が偏っている場合に対して、`tm_scale_continuous_log()` や `tm_scale_continuous_log1p()` といった派生もある。
\index{tmap (package)!categorical}
最後に、`tm_scale_categorical()` は、カテゴリ値を代表し、各カテゴリに固有の色が割り当てられる (Figure \@ref(fig:concat) 右図)。

<div class="figure" style="text-align: center">
<img src="figures/concat-1.png" alt="**tmap** における連続スケールとカテゴリスケール" width="100%" />
<p class="caption">(\#fig:concat)**tmap** における連続スケールとカテゴリスケール</p>
</div>

\index{tmap (package)!いろぱれっと@色パレット}
パレットは、ビンに関連付けられ、前述の `breaks`、`n`、`style` 引数で決定される色域を定義する。
この引数には色ベクトルまたは新しい色パレット名を与えるが、`tmaptools::palette_explorer()` で対話的に選択することができる。
プレフィックスとして `-` を付けると、パレットの順序を逆にすることができる。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">入力データに応じた色パレットなどの美観に関わるデフォルト`値`は、`tmap_options() で確認することができる。
例として、`tmap_options()$values.var` を実行してみよう。</div>\EndKnitrBlock{rmdnote}

\index{いろぱれっと@色パレット}
色パレット\index{ちずさくせい@地図作成!いろぱれっと@色パレット}は大きく分けて、カテゴリ、連続、発散 (分岐) の三種類がある (Figure \@ref(fig:colpal))。目的に応じてこの三種類を使い分ける。^[
第四の色パレットとして二変量 (bivariate) がある。
これは、地図上の二つの変数の関係を代表する。
]
カテゴリパレットは、区別しやすい色で構成されており、州名や土地被覆クラスなど、特定の順序を持たないカテゴリデータに最適である。
色は直感的にわかるように、例えば川は青、牧草地は緑にする。
カテゴリを増やしすぎると、大きな凡例や多くの色を使った地図は理解できないことがある。^[国別に色分けするように、個別のポリゴンが多い場合、`fill = "MAP_COLORS"` としてみよう。隣接するポリゴンにユニークな色を設定する。]

次に、連続パレットをみてみよう。
連続パレットは、例えば明るい色から暗い色への勾配に沿っており (明るい色は低い値を表す傾向がある)、連続的な (数値) 変数に適している。
連続パレットは、以下のコードで示すように、単色 (例えば、`greens` は明るいから暗い緑へ) または多色/色相 (例えば、`yl_gn_bu` は明るい黄色から緑色を経て青色へのグラデーション) である (出力は示していない)。結果を見るために自分でコードを実行してみよう。


``` r
tm_shape(nz) + 
  tm_polygons("Median_income", fill.scale = tm_scale(values = "greens"))
tm_shape(nz) + 
  tm_polygons("Median_income", fill.scale = tm_scale(values = "yl_gn_bu"))
```

3 番目のパレットである発散パレットは、通常 3 色の間 (紫-白-緑:  Figure \@ref(fig:colpal)) で、通常 2 つの単色パレットの両端を濃い色で結合して作成される。
その主な目的は、ある気温、世帯収入の中央値、干ばつイベントの平均確率など、重要な基準点からの差異を可視化することである。
参照点の値は、`midpoint` の引数を用いて **tmap** で調整することができる。


``` r
tm_shape(nz) + 
  tm_polygons("Median_income",
              fill.scale = tm_scale_continuous(values = "pu_gn_div", 
                                               midpoint = 28000))
```

<div class="figure" style="text-align: center">
<img src="figures/colpal-1.png" alt="カテゴリ、連続色、発散のパレットの例。" width="75%" />
<p class="caption">(\#fig:colpal)カテゴリ、連続色、発散のパレットの例。</p>
</div>

色を扱う際に考慮すべき重要な原則は、「知覚可能性」と「アクセシビリティ」の 2 つである。
まず、地図の色は感覚と合っていなければならない。 
特定の色は、経験や文化的なレンズを通して見ることができる。
例えば、緑は植物や低地を表し、青は水や涼しさを連想させる色である。
また、情報を効果的に伝えるために、色パレットは分かりやすいものが望ましい。
どの数値が低く、どの数値が高いかが明確で、色も徐々に変化することが望ましい。
第二に、色の変化は、多くの人がアクセスできるものでなければならない。
そのため、可能な限り色弱者用のパレットを使うことが大切である。^[`cols4all::c4a_gui()` の "Color Blind Friendliness" パネルの "Color vision" オプションを参照。] 

### 凡例  {#legends}

\index{tmap (package)!はんれい@凡例}
美観変数と設定を決定したのち、地図の凡例スタイルに注意を向けよう。
`tm_legend()` 関数を使うと、タイトル、位置、方向を変えたり、あるいは非表示することができる。
最も重要なのは`タイトル`で、凡例のタイトルとなる。
一般に、タイトルには二つの情報を記述する。一つ目は内容で、二つ目は値の単位である。
以下のコードは、変数名 `Land_area` よりも魅力的な名前を提供することで、この機能を示している (`expression()` は上付き文字を設定するために使用)。


``` r
legend_title = expression("Area (km"^2*")")
tm_shape(nz) +
  tm_polygons(fill = "Land_area", fill.legend = tm_legend(title = legend_title))
```

**tmap** の凡例方向はデフォルトでは縦長 `"portrait"` であるが、`"landscape"` で横長とすることもできる。
凡例の位置は、`position` 引数で設定する。


``` r
tm_shape(nz) +
  tm_polygons(fill = "Land_area",
              fill.legend = tm_legend(title = legend_title,
                                      orientation = "landscape",
                                      position = tm_pos_out("center", "bottom")))
```



凡例の位置 (およびその他の **tmap** の地図要素の位置) は、関数でカスタマイズできる。
最も重要なものを二つ紹介する。

- `tm_pos_out()`: これがデフォルトで、凡例を図郭の外に配置する。
位置については、横方向 (`"left"`、`"center"`、`"right"`) と縦方向 (`"bottom"`、`"center"`、`"top"`) で指定する。
- `tm_pos_in()`: は、図郭内に配置する。
最初の引数は `"left"`、`"center"`、`"right"` のいずれかで、2 番目の引数は `"bottom"`、`"center"`、`"top"` のいずれかである。

または、2 つの値のベクトル (または 0 から 1 の 2 つの値) を与えても良い。この場合、凡例は図郭内に配置される。

### レイアウト  {#layouts}

\index{tmap (package)!れいあうと@レイアウト}
地図レイアウトとは、すべての地図要素を組み合わせて、まとまりのある地図にすることである。
地図要素には、マップされるオブジェクト、地図グリッド (メッシュ)、縮尺バー、タイトル、マージンなどがあり、前のセクションで説明したカラー設定は、地図の見え方に影響を与えるパレットとブレークポイントに関連している。
どちらも微妙な変化をもたらすだろうが、地図が残す印象には同じように大きな影響を与える。

経緯線網\index{tmap (package)!けいいせんもう@経緯線網}、方位記号\index{tmap (package)!ほういきごう@方位記号}、スケールバー\index{tmap (package)!すけーるばー@スケールバー}、タイトルなどの整飾には、それぞれ `tm_graticules()`、`tm_compass()`、`tm_scalebar()`、`tm_title()` といった関数がある (Figure \@ref(fig:na-sb))。^[この他、`tm_grid()`、`tm_logo()`、`tm_credits()` がある。]


``` r
map_nz + 
  tm_graticules() +
  tm_compass(type = "8star", position = c("left", "top")) +
  tm_scalebar(breaks = c(0, 100, 200), text.size = 1, position = c("left", "top")) +
  tm_title("New Zealand ", fontfamily = "HiraginoSans-W3")
```

<div class="figure" style="text-align: center">
<img src="figures/na-sb-1.png" alt="方位記号とスケールバーを追加した地図。" width="65%" />
<p class="caption">(\#fig:na-sb)方位記号とスケールバーを追加した地図。</p>
</div>

また、**tmap** では、様々なレイアウト設定を変更することができる。その一部を、以下のコードで作成し、Figure \@ref(fig:layout1) に図示している (全リストは、`args(tm_layout)` または `?tm_layout` を参照)。


``` r
map_nz + tm_layout(scale = 4, fontfamily = "HiraginoSans-W3")
map_nz + tm_layout(bg.color = "lightblue")
map_nz + tm_layout(frame = FALSE)
```

<div class="figure" style="text-align: center">
<img src="figures/layout1-1.png" alt="レイアウトオプションは、(左から) scale、bg.color、frame の各引数で指定。" width="100%" />
<p class="caption">(\#fig:layout1)レイアウトオプションは、(左から) scale、bg.color、frame の各引数で指定。</p>
</div>

`tm_layout()` の引数は、キャンバス内で地図がどのように配置されるかを制御する。
ここでは、便利なレイアウト設定をご紹介する (一部、Figure \@ref(fig:layout2))。

- `inner.margin` と `outer.margin` はマージンを設定
- `fontface` で制御されるフォント設定と `fontfamily` (訳註: macOS では文字化けを fontfamily = "HiraginoSans-W3" とすることで回避できる)
- 凡例設定は、`legend.show` (凡例を表示すかどうか)、`legend.only` (地図を省略するか)、`legend.outside` (凡例を地図の外に出すか) などの二値オプションで設定するか、あるいは `legend.position` ですべて設定
- 図郭の幅 (`frame.lwd`) と二重線 (`frame.double.line`) を許可するオプション
- `sepia.intensity` (地図のセピア度合) と `saturation` (色・グレースケール) を制御する色設定

<div class="figure" style="text-align: center">
<img src="figures/layout2-1.png" alt="選択したレイアウトオプション。" width="100%" />
<p class="caption">(\#fig:layout2)選択したレイアウトオプション。</p>
</div>

### ファセット地図  {#faceted-maps}

\index{ちずさくせい@地図作成!ふぁせっとちず@ファセット地図}
\index{tmap (package)!ふぁせっとちず@ファセット地図}
ファセット地図は「スモール・マルチプル」とも呼ばれ、多数の地図を横または縦に重ねて構成する [@meulemans_small_2017]。
ファセットは、空間的な関係が時間などの別の変数に対してどのように変化するかを視覚化することができる。
例えば、集落の人口の変化を表現する場合、特定の時点の人口のパネルを並べたファセット地図で表現することができる。
時間の次元は、色などの別の<u>視覚化に関する変数</u>で表現できる。
しかし、これは複数のポイントが重なるため、地図が乱雑になる危険性がある (都市は移動しない！)。

ファセット地図では、一つのジオメトリ・データの属性データのそれぞれの列に対して一つのファセットとなる (`sf` オブジェクトのデフォルトのプロット方法、Chapter \@ref(spatial-class) を参照)。
また、ファセットを用いて、点パターンの経時変化など、ジオメトリの変化を表現することもできる。
このファセット化されたプロットの使用例を Figure \@ref(fig:urban-facet) に示す。


``` r
urb_1970_2030 = urban_agglomerations |> 
  filter(year %in% c(1970, 1990, 2010, 2030))

tm_shape(world) +
  tm_polygons() +
  tm_shape(urb_1970_2030) +
  tm_symbols(fill = "black", col = "white", size = "population_millions") +
  tm_facets_wrap(by = "year", nrow = 2)
```

<div class="figure" style="text-align: center">
<img src="figures/urban-facet-1.png" alt="国連による人口予測に基づき、1970年から2030年までの都市集積の上位30位までを示したファセット地図。" width="100%" />
<p class="caption">(\#fig:urban-facet)国連による人口予測に基づき、1970年から2030年までの都市集積の上位30位までを示したファセット地図。</p>
</div>

このコードでは、**tmap** で作成されたファセット地図の主要な特徴を示している。

- ファセット変数を持たないシェイプは繰り返される (この場合、`world` の国々)
- 変数によって変化する `by` の引数 (この場合は `"year"`)
- `nrow` / `ncol` ファセットが配置される行と列の数を指定

あるいは、`tm_facets_grid()` 関数を使って 3 変数 `rows`、`columns`、`pages` からファセットを作る。

ファセット地図は、変化する空間的関係を示すのに有用なだけでなく、地図アニメーションの基礎としても有用である (Section \@ref(animated-maps) 参照)。

### 差し込み地図

\index{ちずさくせい@地図作成!さしこみちず@差し込み地図}
\index{tmap (package)!さしこみちず@差し込み地図}
差し込み地図とは、メイン地図の中や横に描画される小さな地図のことである。 
コンテキストを提供したり (Figure \@ref(fig:insetmap1))、非連続な領域を接近させて比較を容易にしたり (Figure \@ref(fig:insetmap2))、様々な目的を果たすことが可能である。
また、より小さなエリアに焦点を当てたり、地図と同じエリアを別のトピックでカバーしたりすることもできる。

下の例では、New Zealand の南アルプスの中央部の地図を作成している。
差し込み地図は、メイン地図が New Zealand 全体に対してどのような位置にあるかを示すものである。
最初のステップは、関心のある領域を定義することである。これは、新しい空間オブジェクト `nz_region` を作成することで可能である。


``` r
nz_region = st_bbox(c(xmin = 1340000, xmax = 1450000,
                      ymin = 5130000, ymax = 5210000),
                    crs = st_crs(nz_height)) |> 
  st_as_sfc()
```

ステップ 2 では、New Zealand の南アルプス周辺を示すベース地図を作成する。 
ここは、最も重要なメッセージが述べられている場所である。 


``` r
nz_height_map = tm_shape(nz_elev, bbox = nz_region) +
  tm_raster(col.scale = tm_scale_continuous(values = "YlGn"),
            col.legend = tm_legend(position = c("left", "top"))) +
  tm_shape(nz_height) + tm_symbols(shape = 2, col = "red", size = 1) +
  tm_scalebar(position = c("left", "bottom"))
```

ステップ 3 で、差し込み地図を作成する。 
差し込み地図はコンテキストを示し、関心のある領域を特定するのに役立つ。 
差し込み地図には境界線を記載するなどして、メイン地図の位置を明確に示す必要がある。


``` r
nz_map = tm_shape(nz) + tm_polygons() +
  tm_shape(nz_height) + tm_symbols(shape = 2, col = "red", size = 0.1) + 
  tm_shape(nz_region) + tm_borders(lwd = 3) +
  tm_layout(bg.color = "lightblue")
```

散布図など通常のグラフと地図の違いの一つとして、入力データは地図のアスペクト比を決定する。
よって、この場合、`nz_region` と `nz` という二つのデータセットのアスペクト比を計算する必要がある。
`norm_dim()` 関数は、オブジェクトの幅 (`"w"`) と高さ (`"h"`) を正規化する (画像デバイスは `"snpc"` の単位を理解する)。


``` r
library(grid)
norm_dim = function(obj){
    bbox = st_bbox(obj)
    width = bbox[["xmax"]] - bbox[["xmin"]]
    height = bbox[["ymax"]] - bbox[["ymin"]]
    w = width / max(width, height)
    h = height / max(width, height)
    return(unit(c(w, h), "snpc"))
}
main_dim = norm_dim(nz_region)
ins_dim = norm_dim(nz)
```

アスペクト比を得て、`viewport()` 関数を使い、二つの地図 (主地図と差し込み地図) の大きさと位置を指定する。
viewport とは、ある瞬間のグラフィック要素を描画するために使用するグラフィックデバイスの一部である。
私たちのメイン地図の viewport は、ちょうどそのアスペクト比の表現である。


``` r
main_vp = viewport(width = main_dim[1], height = main_dim[2])
```

差し込み地図の表示領域は、大きさと位置を指定する必要がある。
ここでは、メイン地図の半分の大きさにするために幅と高さに 0.5 をかけ、メイン地図フレームの右下から 0.5 cm の位置に配置する。


``` r
ins_vp = viewport(width = ins_dim[1] * 0.5, height = ins_dim[2] * 0.5,
                  x = unit(1, "npc") - unit(0.5, "cm"), y = unit(0.5, "cm"),
                  just = c("right", "bottom"))
```

最後に、新規にキャンバスを作り、メイン地図を表示し、メイン地図の領域内に差し込み地図を配置する。


``` r
grid.newpage()
print(nz_height_map, vp = main_vp)
pushViewport(main_vp)
print(nz_map, vp = ins_vp)
```

<div class="figure" style="text-align: center">
<img src="figures/insetmap1-1.png" alt="差し込み地図で背景を説明 - New Zealand の南アルプスの中央部の位置。" width="100%" />
<p class="caption">(\#fig:insetmap1)差し込み地図で背景を説明 - New Zealand の南アルプスの中央部の位置。</p>
</div>

差し込み地図を保存するには、グラフィックデバイス (Section \@ref(visual-outputs) 参照) を使うか、`tmap_save()` 関数に引数 `insets_tm` および `insets_vp` を設定する方法がある。

また、差し込み地図は、非連続なエリアを 1 つの地図にするために使用する。
よく使われる例はアメリカ合衆国の地図で、アメリカ本土とハワイ、アラスカで構成されている。
このようなケースでは、個々の差し込みに最適なプロジェクションを見つけることが非常に重要である (詳しくは Chapter \@ref(reproj-geo-data) を参照)。
`tm_shape()` の引数 `crs` に US National Atlas Equal Area の EPSG コードを指定すれば、米国本土の地図に US National Atlas Equal Area を使用することができる。


``` r
us_states_map = tm_shape(us_states, crs = "EPSG:9311") + 
  tm_polygons() + 
  tm_layout(frame = FALSE)
```

残りのオブジェクト `hawaii` と `alaska` は、すでに適切な投影を持っている。したがって、2 つの地図を別々に作成するだけでよい。


``` r
hawaii_map = tm_shape(hawaii) +
  tm_polygons() + 
  tm_title("Hawaii") +
  tm_layout(frame = FALSE, bg.color = NA, 
            title.position = c("LEFT", "BOTTOM"))
alaska_map = tm_shape(alaska) +
  tm_polygons() + 
  tm_title("Alaska") +
  tm_layout(frame = FALSE, bg.color = NA)
```

これら 3 つの地図を組み合わせ、サイズを調整し配置することで、最終的な地図ができあがる。


``` r
us_states_map
print(hawaii_map, vp = grid::viewport(0.35, 0.1, width = 0.2, height = 0.1))
print(alaska_map, vp = grid::viewport(0.15, 0.15, width = 0.3, height = 0.3))
```

<div class="figure" style="text-align: center">
<img src="figures/insetmap2-1.png" alt="アメリカ合衆国の地図。" width="100%" />
<p class="caption">(\#fig:insetmap2)アメリカ合衆国の地図。</p>
</div>

上記で紹介したコードはコンパクトで、他の差し込み地図のベースとして使用することができる。ただし、Figure \@ref(fig:insetmap2) ではハワイとアラスカの位置とサイズがうまく表現されていないことがわかる。
より詳細なアプローチについては、**geocompkg** の [`us-map`](https://geocompx.github.io/geocompkg/articles/us-map.html) vignette を参照。

## 地図アニメーション  {#animated-maps}

\index{ちずさくせい@地図作成!ちずあにめーしょん@地図アニメーション}
\index{tmap (package)!ちずあにめーしょん@地図アニメーション}
Section \@ref(faceted-maps) で紹介されているファセット地図は、変数の空間分布が (例えば時間経過とともに) どのように変化するかを示すことができるが、このアプローチには欠点がある。
ファセットは数が多いと小さくなる。
さらに、画面やページ上で各ファセットが物理的に分離しているため、ファセット間の微妙な差異を検出することが難しい。

地図アニメーションは、これらの問題を解決する。
デジタル版でしか表示できないが、より多くのコンテンツがオンラインに移行するにつれて、これは問題ではなくなってきている。
印刷された地図から地図アニメーション (またはインタラクティブ) バージョンを含むウェブページに読者をリンクすることで、地図を生き生きとさせることができる。
R でアニメーションを生成する方法はいくつかあり、**ggplot2** をベースにした **ganimate** のようなアニメーションパッケージもある (Section \@ref(other-mapping-packages) を参照)。
このセクションでは、**tmap** を使った地図アニメーションの作成に焦点を当てる。構文はこれまでのセクションでも使っており、アプローチの柔軟性がある。

Figure \@ref(fig:urban-animated) は、地図アニメーションの簡単な例である。
ファセットプロットとは異なり、複数の地図を一画面に押し込むことはなく、世界で最も人口の多い集積地の空間分布が時間とともにどのように進化していくかを見ることができる (アニメーション版は同書のウェブサイトを参照)。

<div class="figure" style="text-align: center">
<img src="images/urban-animated.gif" alt="1950年から2030年までの、国連による人口予測に基づく都市集積の上位30位を示した地図アニメーション。アニメーション版は、geocompr.robinlovelace.net で見ることができる。" width="100%" />
<p class="caption">(\#fig:urban-animated)1950年から2030年までの、国連による人口予測に基づく都市集積の上位30位を示した地図アニメーション。アニメーション版は、geocompr.robinlovelace.net で見ることができる。</p>
</div>



Figure \@ref(fig:urban-animated) に示した地図アニメーションは、Section \@ref(faceted-maps) で示したファセット・地図を生成するのと同じ **tmap** 技術を使用して作成することができる。
ただし、`tm_facets_wrap()` の引数に関連して、2 つの違いがある。

- `nrow = 1, ncol = 1` として、一つの時間を一つのレイヤとしている
- `free.coords = FALSE` で、アニメーションのために地図の範囲を維持する

追加した引数を、次のコードチャンクで示そう。^[`tm_facets_pagewise()` を使うと、さらに簡潔になる。]


``` r
urb_anim = tm_shape(world) + tm_polygons() + 
  tm_shape(urban_agglomerations) + tm_symbols(size = "population_millions") +
  tm_facets_wrap(by = "year", nrow = 1, ncol = 1, free.coords = FALSE)
```

結果である `urb_anim` は、各年度の個別の地図のセットを表している。
最終的には、`tmap_animation()` でこれらを合成して、`.gif` ファイルとして保存する。
次のコマンドは、Figure \@ref(fig:urban-animated) に示されたアニメーションを作成する。ただし、いくつかの要素が欠けているので、演習で追加する。


``` r
tmap_animation(urb_anim, filename = "urb_anim.gif", delay = 25)
```

地図アニメーションの威力を示すもう一つの例が、Figure \@ref(fig:animus) である。
これは、アメリカにおける州の発達を示すもので、最初は東部で形成され、その後徐々に西部へ、最後は内陸部へと発展していった。
この地図を再現するためのコードは、本書の GitHub リポジトリのスクリプト `code/09-usboundaries.R` にある。



<div class="figure" style="text-align: center">
<img src="https://user-images.githubusercontent.com/1825120/38543030-5794b6f0-3c9b-11e8-9da9-10ec1f3ea726.gif" alt="米国における人口増加、州形成、境界線の変化を示す地図アニメーション (1790-2010年)。アニメーション版は r.geocompx.org でオンライン公開。" width="100%" />
<p class="caption">(\#fig:animus)米国における人口増加、州形成、境界線の変化を示す地図アニメーション (1790-2010年)。アニメーション版は r.geocompx.org でオンライン公開。</p>
</div>

## インタラクティブ地図  {#interactive-maps}

\index{ちずさくせい@地図作成!いんたらくてぃぶちず@インタラクティブ地図}
\index{tmap (package)!いんたらくてぃぶちず@インタラクティブ地図}
静止画や地図アニメーションは、地理データセットを盛り上げることができるが、インタラクティブな地図は、それらを新しいレベルに引き上げることができる。
インタラクティブ性には様々な形態があるが、最も一般的で有用なのは、地理データセットのどの部分でもパンしたりズームしたりして、「ウェブ地図」の上に重ねてコンテキストを表示す機能である。
より高度なインタラクティブ性のレベルとしては、さまざまなフィーチャをクリックすると表示されるポップアップ、つまりインタラクティブラベルのようなものがある。
より高度なインタラクティブ機能としては、下記の **mapdeck** の例で示したように、地図を傾けたり回転させたりする機能や、ユーザーがパンやズームをすると自動的に更新される「動的にリンクした」サブプロット [@pezanowski_senseplace3_2018]  を提供する機能などが挙げられる。

しかし、インタラクティブ性の最も重要なタイプは、インタラクティブまたは「スリッピー」なウェブ地図上での地理データの表示である。
2015年にリリースされた **leaflet** (leaflet JavaScript ライブラリを使用) パッケージは、R 内からインタラクティブな Web 地図の作成に革命をもたらし、多くのパッケージがこれらの基盤の上に新機能を追加し (例: **leaflet.extras2**)、Web 地図の作成を静的地図作成と同じくらいシンプルにしている (例: **mapview** や **tmap** など)。
ここでは、各アプローチを紹介した順と逆に説明する。
**tmap** (すでに学習済みの構文)、**mapview**\index{mapview (package)}、**mapdeck**\index{mapdeck (package)}そして最後に **leaflet** \index{leaflet (package)} (対話型地図の低レベル制御を提供) を使って、動く地図を作成する方法を探究する。

Section \@ref(static-maps) で述べた **tmap** は、同じコードを使って静的な地図とインタラクティブな地図を作ることができる。
`tmap_mode("view")` というコマンドでビューモードに切り替えることで、任意の時点でインタラクティブ表示に切り替えることができる。
以下のコードは、`tmap` オブジェクト `map_nz` に基づいて New Zealand のインタラクティブ地図を作成し、Section \@ref(map-obj) で作成し、Figure \@ref(fig:tmview) で図示している。


``` r
tmap_mode("view")
map_nz
```

<div class="figure" style="text-align: center">
<iframe src="https://geocompx.org/static/img/tmview-1.html" width="100%" height="400px" data-external="1"></iframe>
<p class="caption">(\#fig:tmview)**tmap** のビューモードで作成されたNew Zealand のインタラクティブ地図。インタラクティブ版は r.geocompx.org からオンラインで入手可能。</p>
</div>

インタラクティブモードが「オン」になったので、**tmap** で作成したすべての地図が起動する (インタラクティブな地図を作成する別の方法として、`tmap_leaflet` 機能がある)。
このインタラクティブモードの特筆すべき点は、以下のデモのように `tm_basemap()` (または `tmap_options()`) でベース地図を指定できることである (結果は表示していない)。


``` r
map_nz + tm_basemap(server = "OpenTopoMap")
```

あまり知られていないが、**tmap** の表示モードは、ファセット・プロットにも対応している。
この場合、`tm_facets_wrap()` の引数 `sync` を使用すると、以下のコードで作成した Figure \@ref(fig:sync) のように、複数の地図を作成し、ズームとパンの設定を同期させることができる。


``` r
world_coffee = left_join(world, coffee_data, by = "name_long")
facets = c("coffee_production_2016", "coffee_production_2017")
tm_shape(world_coffee) + tm_polygons(facets) + 
  tm_facets_wrap(nrow = 1, sync = TRUE)
```

<div class="figure" style="text-align: center">
<img src="images/interactive-facets.png" alt="2016年と2017年の世界のコーヒー生産量を同期させたファセット化されたインタラクティブ地図で、tmapのビューモードの動作を実演。" width="100%" />
<p class="caption">(\#fig:sync)2016年と2017年の世界のコーヒー生産量を同期させたファセット化されたインタラクティブ地図で、tmapのビューモードの動作を実演。</p>
</div>

同じ機能で **tmap** をプロットモードに戻す。


``` r
tmap_mode("plot")
#> ℹ tmap mode set to "plot".
```

**tmap** を使いこなせない場合は、**mapview**\index{mapview (package)} を使ってインタラクティブ地図を作成するのが一番手っ取り早いだろう。
以下の 1 行コードは、さまざまな地理データ形式をインタラクティブに探索するための信頼できる方法である。


``` r
mapview::mapview(nz)
```

<div class="figure" style="text-align: center">
<img src="images/mapview.png" alt="**mapview** の動作イメージ図。" width="100%" />
<p class="caption">(\#fig:mapview)**mapview** の動作イメージ図。</p>
</div>

**mapview** は簡潔な構文でありながら、強力な機能を備えている。
デフォルトでは、マウスの位置情報、(ポップアップによる) 属性問い合わせ、スケールバー、レイヤへのズームボタンなどの標準的な GIS 機能が提供されている。
データセットを複数のレイヤに「バースト」する機能や、`+` の後に地理的オブジェクトの名前を付けて複数のレイヤを追加する機能など、高度な制御を提供する。 
さらに、属性の自動的な色付けも可能である (引数 `zcol`)。
要するに、データドリブンの **leaflet** API\index{API} と考えることができる (**leaflet** については後述する)。
**mapview** は常に空間オブジェクト (`sf` と `SpatRaster`) を最初の引数として期待することから、パイプで繋げてもうまく機能する。 
次の例では、**sf** を使って直線とポリゴンを交差させ、**mapview** (Figure \@ref(fig:mapview2)) で可視化する場合を考えてみよう。


``` r
library(mapview)
oberfranken = subset(franconia, district == "Oberfranken")
trails |>
  st_transform(st_crs(oberfranken)) |>
  st_intersection(oberfranken) |>
  st_collection_extract("LINESTRING") |>
  mapview(color = "red", lwd = 3, layer.name = "trails") +
  mapview(franconia, zcol = "district") +
  breweries
```

<div class="figure" style="text-align: center">
<img src="images/mapview-example.png" alt="sf ベースのパイプ式の末尾で **mapview** を使用。" width="100%" />
<p class="caption">(\#fig:mapview2)sf ベースのパイプ式の末尾で **mapview** を使用。</p>
</div>

注意点としては、**mapview** のレイヤは `+` 演算子で追加する (**ggplot2** や **tmap** に似ている)。 
デフォルトでは、**mapview** はユーザーフレンドリーで機能の多い leaflet JavaScript ライブラリを使い、地図を出力する。
しかし、他のレンダリングライブラリの方がパフォーマンスが良い (巨大なデータでもスムーズ)。
**mapview** は、レンダリングライブラリ (`"leafgl"` と `"mapdeck"`) を、`mapviewOptions()` で設定することができる。^[巨大なラスタデータの可視化には、`mapviewOptions(georaster = TRUE)` も試してみると良いだろう。]
**mapview** の詳細については、パッケージのウェブサイトを参照。 [r-spatial.github.io/mapview/](https://r-spatial.github.io/mapview/articles/) を参照。

R でインタラクティブな地図を作成する方法は他にもある。
例えば、**googleway**\index{googleway (package)} パッケージは、柔軟で拡張性の高いインタラクティブなマッピングインターフェースを提供する
(詳細は [`googleway-vignette`](https://cran.r-project.org/package=googleway/vignettes/googleway-vignette.html) 参照)。
同じ著者による別のアプローチとして、**[mapdeck](https://github.com/SymbolixAU/mapdeck)** があり、Uber の `Deck.gl` フレームワーク \index{mapdeck (package)}  にアクセスできるようになっている。
WebGL を使用することで、大規模なデータセット (最大数百万点) をインタラクティブに可視化することができる。
本パッケージは、Mapbox [access tokens](https://docs.mapbox.com/help/getting-started/access-tokens/) を使用している。本パッケージを使用する前に、登録する必要がある。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">以下のブロックは、`MAPBOX=your_unique_key` という形式で R 環境にアクセストークンがあることを想定している。
これは、**usethis** パッケージの `edit_r_environ()` で追加することができる。</div>\EndKnitrBlock{rmdnote}

**mapdeck** のユニークな点は、Figure \@ref(fig:mapdeck) で図示するようにインタラクティブな 2.5 次元パースペクティブを提供できる点にある。
これによって、地図をパン、ズーム、回転することができる上に、地図から「押し出した」データを見ることができるのである。
Figure \@ref(fig:mapdeck) は、英国における交通事故を可視化したもので、棒の高さは地域ごとの死傷者数を表している。




``` r
library(mapdeck)
set_token(Sys.getenv("MAPBOX"))
crash_data = read.csv("https://git.io/geocompr-mapdeck")
crash_data = na.omit(crash_data)
ms = mapdeck_style("dark")
mapdeck(style = ms, pitch = 45, location = c(0, 52), zoom = 4) |>
  add_grid(data = crash_data, lat = "lat", lon = "lng", cell_size = 1000,
           elevation_scale = 50, colour_range = hcl.colors(6, "plasma"))
```

<div class="figure" style="text-align: center">
<img src="images/mapdeck-mini.png" alt="**mapdeck** によって生成された、イギリス全土の道路交通事故死傷者数を表す地図。1 km のセルの高さは事故件数を表す。" width="100%" />
<p class="caption">(\#fig:mapdeck)**mapdeck** によって生成された、イギリス全土の道路交通事故死傷者数を表す地図。1 km のセルの高さは事故件数を表す。</p>
</div>

ブラウザでは、ズームやドラッグのほか、`Cmd` / `Ctrl` を押すと、地図を回転させたり傾けたりすることができる。
[`mapdeck` vignette](https://cran.r-project.org/package=mapdeck/vignettes/mapdeck.html) で示されているように、パイプ演算子で複数のレイヤを追加することができる。
**mapdeck** は `sf` オブジェクトもサポートしている。先のコードチャンクの `add_grid()` 関数呼び出しを `add_polygon(data = lnd, layer_id = "polygon_layer")` に置き換えて、インタラクティブな傾いた地図にロンドンを表すポリゴンを追加してみるとわかる。



最後に、**leaflet**\index{leaflet (package)} は R  で最も成熟し、広く使われている対話型の地図作成パッケージである。
**leaflet** は、Leaflet JavaScript ライブラリへの比較的低レベルのインタフェースを提供し、その引数の多くは、オリジナルの JavaScript ライブラリのドキュメントを読めば理解できる ( [leafletjs.com](https://leafletjs.com/) を参照)。

Leaflet 地図は `leaflet()` で作成され、その結果は `leaflet` 地図オブジェクトとなり、他の **leaflet** 関数にパイプで渡すことができる。
これにより、Figure \@ref(fig:leaflet) を生成する以下のコードで示すように、複数の地図レイヤや制御設定をインタラクティブに追加することができる (詳しくは [rstudio.github.io/leaflet/](https://rstudio.github.io/leaflet/) を参照)。


``` r
pal = colorNumeric("RdYlBu", domain = cycle_hire$nbikes)
leaflet(data = cycle_hire) |> 
  addProviderTiles(providers$CartoDB.Positron) |>
  addCircles(col = ~pal(nbikes), opacity = 0.9) |> 
  addPolygons(data = lnd, fill = FALSE) |> 
  addLegend(pal = pal, values = ~nbikes) |> 
  setView(lng = -0.1, 51.5, zoom = 12) |> 
  addMiniMap()
```

<div class="figure" style="text-align: center">
<img src="images/leaflet-1.png" alt="ロンドン市内の自転車レンタルポイントを紹介した **leaflet** パッケージの実例。インタラクティブ版は[オンライン](https://geocompr.github.io/img/leaflet.html)を参照。" width="100%" />
<p class="caption">(\#fig:leaflet)ロンドン市内の自転車レンタルポイントを紹介した **leaflet** パッケージの実例。インタラクティブ版は[オンライン](https://geocompr.github.io/img/leaflet.html)を参照。</p>
</div>

## 地図アプリ  {#mapping-applications}

\index{ちずさくせい@地図作成!ちずあぷり@地図アプリ}
Section \@ref(interactive-maps) で示したインタラクティブなウェブ地図は、遠くまで行くことができる。
表示するレイヤを慎重に選択し、ベース地図とポップアップを使用することで、ジオコンピュテーションを含む多くのプロジェクトの主な結果を伝えることができる。
しかし、ウェブ地図というアプローチでインタラクティブ性を追求することには限界がある。

- 地図はパン、ズーム、クリックといったインタラクティブな動きをするが、コードは静的で、ユーザーインターフェースは固定されている。
- ウェブ地図では、すべての地図コンテンツが一般的に静的であるため、ウェブ地図は大規模なデータセットを容易に扱うことができない。
- 変数間の関係を示すグラフや「ダッシュボード」のようなインタラクティブなレイヤを追加することは、ウェブ地図のアプローチでは困難である

これらの制約を克服するためには、静的なウェブ地図にとどまらず、地理空間系のフレームワークや地図サーバーを利用することが必要である。
この分野の製品には、[GeoDjango](https://docs.djangoproject.com/en/2.0/ref/contrib/gis/)\index{GeoDjango} (Django Web フレームワークを拡張したもので、[Python](https://github.com/django/django)\index{Python})、[MapServer](https://github.com/mapserver/mapserver)\index{MapServer} (Web アプリケーション開発用のフレームワークで、大部分が C と C++\index{C++} で書かれている) や [GeoServer](https://github.com/geoserver/geoserver) (Java\index{Java} で書かれた成熟した強力な地図サーバ) が含まれる。
これらはそれぞれ拡張性があり、毎日何千人もの人々に地図を提供することが可能である (あなたの地図に対する人々の関心が十分に高ければの話であるが)。
欠点としては、このようなサーバーサイドのソリューションは、セットアップと保守に多くの熟練した開発者の時間を必要とし、地理空間データベース管理者 ([DBA](https://wiki.gis.com/wiki/index.php/Database_administrator)) などの役割を持つ人々を巻き込んでしまうこともよくある。

R の場合は幸運なことに、**shiny**\index{shiny (package)} を使って、ウェブ地図アプリケーションを素早く作成できるようになった。
オープンソース本 [Mastering Shiny](https://mastering-shiny.org/) で説明されているように、 **shiny** は、R コードをインタラクティブなウェブアプリに変換する R パッケージでありフレームワークである [@wickham_mastering_2021]。
<!-- `tmap::renderTmap()` と --> [`leaflet::renderLeaflet()`](https://rstudio.github.io/leaflet/shiny.html) を使うことで、shiny アプリにインタラクティブ地図を追加することができる。
このセクションでは、ウェブ地図の観点から **shiny** の基本を学び、100 行未満のコードで全画面の地図アプリケーションを完成させることができる。

**shiny** の仕組みは、[shiny.posit.co](https://shiny.posit.co/) に詳しく書かれているが、「フロントエンド」 (ユーザーが見る部分) と「バックエンド」コードという 2 つの構成要素がある。
**shiny** アプリでは、これらの要素は通常、`app フォルダ`内にある `app.R` という R スクリプト内の `ui` と `server` というオブジェクトで作成される。
これにより、ウェブの地図アプリケーションを 1 つのファイルで表現することも可能で、例えば、本書の GitHub リポジトリにある [`CycleHireApp/app.R`](https://github.com/geocompx/geocompr/blob/main/apps/CycleHireApp/app.R) は単一のファイルで表現している。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">**shiny** アプリでは、これらは `ui.R` (ユーザーインターフェースの略) と `server.R` ファイルに分けられることが多い。この命名規則は、一般向けの Web サイトで shiny アプリを提供するサーバーサイド Linux アプリケーション、`shiny-server` で使用されている。
`shiny-server` は、'app フォルダ' 内にある `app.R` という単一ファイルで定義されるアプリを提供することもある。
詳細は https://github.com/rstudio/shiny-server 。</div>\EndKnitrBlock{rmdnote}

大規模なアプリを検討する前に、「lifeApp」と名付けた最小限の例を実際に見てみよう。^[
ここでいう「アプリ」とは「Web アプリケーション」のことであり、一般的な意味であるスマートフォンのアプリと混同しないようにしよう。
]
以下のコードでは、`shinyApp()` というコマンドで、lifeApp を定義して起動する。これは、平均寿命のレベルが低い国を表示させることができるインタラクティブなスライダーである (Figure \@ref(fig:lifeApp) を参照)。


``` r
library(shiny)   # shiny
library(leaflet) # renderLeaflet 関数
library(spData)  # world データを読み込む 
ui = fluidPage(
  sliderInput(inputId = "life", "Life expectancy", 49, 84, value = 80),
      leafletOutput(outputId = "map")
  )
server = function(input, output) {
  output$map = renderLeaflet({
    leaflet() |> 
      # addProviderTiles("OpenStreetMap.BlackAndWhite") |>
      addPolygons(data = world[world$lifeExp < input$life, ])})
}
shinyApp(ui, server)
```

<div class="figure" style="text-align: center">
<img src="images/shiny-app.png" alt="shiny で作成したWeb地図アプリケーションの最小限の例を示す画面。" width="100%" />
<p class="caption">(\#fig:lifeApp)shiny で作成したWeb地図アプリケーションの最小限の例を示す画面。</p>
</div>

lifeApp の**ユーザーインターフェース** (`ui`) は `fluidPage()` で作成されている。
これには、入力と出力の「ウィジェット」、この場合、`sliderInput()` (他にも多くの `*Input()` 関数が利用できる) と `leafletOutput()` が含まれる。
ウィジェットはデフォルトで列方向に配置されており、Figure \@ref(fig:lifeApp) でスライダーインターフェースが地図の真上に配置されている理由を説明している (列方向にコンテンツを追加する方法については `?column` を参照)。

**サーバー側** (`server`) は、`input` と `output` を引数に持つ関数である。
`output` は、`render*()` 関数によって生成された要素を含むオブジェクトのリストである。この例では、`renderLeaflet()` が `output$map` を生成している。
サーバーで参照される `input$life` などの入力要素は、上記のコードで `ui` --- `inputId = "life"` によって定義される中に存在する要素に関連していなければならない。
関数 `shinyApp()` は `ui` と `server` の両要素を結合し、その結果を新しい R プロセスで対話的に提供する。
Figure \@ref(fig:lifeApp) に表示されている地図のスライダーを動かすと、ユーザーインターフェースでは見えないようになっているが、実際には R のコードが再実行される。

この基本的な例をもとに、どこにヘルプがあるか (`?shiny` 参照) を知っておけば、あとは読むのをやめてプログラミングを始めるのが一番だろうね。
次のステップとして推奨されるのは、以前に紹介した  [`CycleHireApp/app.R`](https://github.com/geocompx/geocompr/blob/main/apps/CycleHireApp/app.R) スクリプトを任意の integrated development environment (IDE) で開き、それを修正して繰り返し実行することである。
この例では、**shiny** で実装されたウェブ地図アプリケーションのコンポーネントの一部が含まれており、それらがどのように動作するかを「照らす」べきものである。

`CycleHireApp/app.R` スクリプトには、単純な 'lifeApp' の例で示されたものを超える **shiny** 関数が含まれている。[shiny.robinlovelace.net/CycleHireApp](https://shiny.robinlovelace.net/CycleHireApp) 参照。
`reactive()` と `observe()` (ユーザーインターフェースに反応する出力を作成するため --- `?reactive` 参照) と `leafletProxy()` (すでに作成されている `leaflet` オブジェクトを変更するため) がある。
このような要素は、**shiny** で実装された Web 地図アプリケーションの作成を可能にする [@lovelace_propensity_2017].。
RStudio の **leaflet** [ウェブサイト](https://rstudio.github.io/leaflet/shiny.html) の shiny セクションで説明されているように、新しいレイヤの描画やデータのサブセットなどの高度な機能を含むさまざまな「イベント」をプログラムすることが可能である。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">**shiny** アプリの実行方法はたくさんある。
RStudio を使用している場合、最も簡単な方法は、`app.R`、`ui.R`、`server.R` を開いている際に、Source ペインの右上になる 'Run App' ボタンを押すことである。
別の方法としては、`runApp()` に最初の引数にアプリのコードとデータを含むフォルダを指定することである。`runApp("CycleHireApp")` という例では、作業ディレクトリ中の `CycleHireApp` フォルダに `app.R` スクリプトがある。
Unix コマンドラインの場合は、`Rscript -e 'shiny::runApp("CycleHireApp")'` コマンドでアプリを立ち上げることができる。</div>\EndKnitrBlock{rmdnote}

`CycleHireApp` などのアプリを試すことで、R によるウェブ地図アプリケーションの知識だけでなく、実践的なスキルも身につけることができる。
例えば、`setView()` の内容を変更すると、アプリが起動されたときにユーザーに表示される開始バウンディングボックスが変更される。
このような実験は、ランダムに行うよりも、関連する文書を参照し、`?shiny` を始めとして、演習で提起したように問題を解決する動機で行うべきである。

このように **shiny** を使用することで、地図アプリケーションのプロトタイプ作成をこれまで以上に迅速かつ身近に行うことができる (**shiny** アプリケーション https://shiny.posit.co/deploy/ の実装は、この章の範囲を超えた別のトピック)。
最終的にアプリケーションが異なる技術で展開されるとしても、**shiny** によって、ウェブ地図アプリケーションが比較的少ないコード行数で開発できることは間違いない (CycleHireApp の場合、86行)。
しかし、shiny アプリは巨大になる傾向がある。
例えば、[pct.bike](https://www.pct.bike/) でホストされている Propensity to Cycle Tool (PCT) は、英国運輸省の資金援助による全国規模の地図ツールである。
PCT は毎日何十人もの人が利用しており、1,000行以上の [コード](https://github.com/npct/pct-shiny/blob/master/regions_www/m/server.R) [@lovelace_propensity_2017]  に基づいた複数のインタラクティブな要素を備えている。

このようなアプリの開発には時間と労力がかかるが、**shiny** は再現性のあるプロトタイプ作成のためのフレームワークを提供し、開発プロセスを支援するはずである。
**shiny** でプロトタイプを簡単に開発することの問題点として、地図アプリケーションの目的が詳細に想定されていない段階でプログラミングを開始する誘惑に駆られることが挙げられる。
そのため、**shiny** を提案しながらも、インタラクティブ地図のプロジェクトの第一段階として、ペンと紙という古くからある技術から始めることを推奨している。
このように、プロトタイプのウェブアプリケーションは、技術的な考慮事項ではなく、開発者の動機と想像力によって制限されるべきものなのである。

<div class="figure" style="text-align: center">
<iframe src="https://shiny.robinlovelace.net/CycleHireApp/" width="690" height="400px" data-external="1"></iframe>
<p class="caption">(\#fig:CycleHireApp-html)CycleHireApp は、住んでいる場所と必要な自転車に基づいて、最も近い自転車レンタルステーションを見つけるためのシンプルなウェブマッピングアプリケーション。インタラクティブ版は geocompr.robinlovelace.net で確認できる。</p>
</div>

## その他の地図作成パッケージ  {#other-mapping-packages}

**tmap** は、さまざまな静的地図 (Section \@ref(static-maps)) を作成するための強力なインターフェースを提供し、インタラクティブな地図 (Section \@ref(interactive-maps)) もサポートしている。
しかし、R で地図を作成するためのオプションは他にもたくさんある。
このセクションの目的は、これらの一部を紹介し、追加リソースのポインタを提供することである。地図作成は、R パッケージの開発において驚くほど活発な分野なので、ここでカバーしきれないほど多くのことを学ぶことができる。

最も成熟した選択肢は、コアな空間パッケージである **sf** (Section \@ref(basic-map)) と **terra** (Section \@ref(basic-map-raster)) が提供する `plot()` メソッドを使用することである。
これらのセクションで触れていないが、ベクタとラスタのオブジェクトのプロットメソッドは、組み合わせて同じプロットエリアに描画することができる (**sf** プロットのキーやマルチバンドのラスタなどの要素はこれを邪魔する)。
この動作は、Figure \@ref(fig:nz-plot) を生成する次のコードチャンクで説明される。
`plot()` には他にも多くのオプションがあり、`?plot` のヘルプページと **sf** 5 番目の vignette [`sf5`](https://cran.r-project.org/package=sf/vignettes/sf5.html) のリンクをたどって調べることができる (訳注: [vignette 日本語版](https://www.uclmail.net/users/babayoshihiko/R/))。


``` r
g = st_graticule(nz, lon = c(170, 175), lat = c(-45, -40, -35))
plot(nz_water, graticule = g, axes = TRUE, col = "blue")
terra::plot(nz_elev / 1000, add = TRUE, axes = FALSE)
plot(st_geometry(nz), add = TRUE)
```

<div class="figure" style="text-align: center">
<img src="figures/nz-plot-1.png" alt="plot() で作成したNew Zealand の地図。右の凡例は標高 (海抜 1000 m) を示している。" width="100%" />
<p class="caption">(\#fig:nz-plot)plot() で作成したNew Zealand の地図。右の凡例は標高 (海抜 1000 m) を示している。</p>
</div>

**tidyverse**\index{tidyverse (package)} のプロットパッケージ **ggplot2** は `sf` オブジェクトを `geom_sf()`\index{ggplot2 (package)} でサポートしている。
構文は **tmap** で使用されているものと似ている。
最初は `ggplot()` で、次に `+ geom_*()` を追加釣ることで、レイヤを追加する。ここで `*` は、`geom_sf()` (`sf` オブジェクトの場合) や `geom_points()` (点の場合) などのレイヤタイプを表す。
   
**ggplot2** はデフォルトで経緯度図郭線を描画する。
経緯度図郭線のデフォルト設定は、`scale_x_continuous()` , `scale_y_continuous()` または  [`coord_sf(datum = NA)`](https://github.com/tidyverse/ggplot2/issues/2071) で上書きできる。
その他の注目すべき特徴としては、`aes()` でカプセル化された引用符なしの変数名を使って、どの美観が異なるかを示したり、`data` 引数を使ってデータソースを切り替えたりしている。以下のコードチャンクでは Figure \@ref(fig:nz-gg2) を作成している。


``` r
library(ggplot2)
g1 = ggplot() + geom_sf(data = nz, aes(fill = Median_income)) +
  geom_sf(data = nz_height) +
  scale_x_continuous(breaks = c(170, 175))
g1
```

また、**ggplot2** をベースにした地図の利点として、**plotly** パッケージ\index{plotly (package)} の関数 `ggplotly()` を使って表示すると、簡単にインタラクティブなレベルを与えることができることが挙げられる。
例えば、`plotly::ggplotly(g1)` を試してみて、その結果を [blog.cpsievert.me](https://blog.cpsievert.me/2018/03/30/visualizing-geo-spatial-data-with-sf-and-plotly/) で説明されている他の **plotly** 地図作成関数と比較してみてみよう。



**gplot2** の利点は、強力なユーザコミュニティと多くのアドオンパッケージを持っていることである。
例えば、**ggplot2** の地図機能を強化するために、北矢印 (`annotation_north_arrow()`) やスケールバー (`annotation_scale()`) あるいは背景タイル (`annotation_map_tile()`) を追加する **ggspatial** がある。
また、`layer_spatial()` は様々な空間データクラスを扱うことができる。
これによって、Figure \@ref(fig:nz-gg2) で示すように、**terra** の `SpatRaster` オブジェクトをプロットすることができる。
 

``` r
library(ggspatial)
ggplot() + 
  layer_spatial(nz_elev) +
  geom_sf(data = nz, fill = NA) +
  annotation_scale() +
  scale_x_continuous(breaks = c(170, 175)) +
  scale_fill_continuous(na.value = NA)
```

<div class="figure" style="text-align: center">
<img src="figures/nz-gg2-1.png" alt="ggplot2 のみ (左) と ggplot2 と ggspatial (右) で生成したNew Zealand 地図の比較。" width="45%" /><img src="figures/nz-gg2-2.png" alt="ggplot2 のみ (左) と ggplot2 と ggspatial (右) で生成したNew Zealand 地図の比較。" width="45%" />
<p class="caption">(\#fig:nz-gg2)ggplot2 のみ (左) と ggplot2 と ggspatial (右) で生成したNew Zealand 地図の比較。</p>
</div>

同時に、**ggplot2** にはいくつかの欠点がある。
`geom_sf()` 関数は、空間[データ](https://github.com/tidyverse/ggplot2/issues/2037) から使用する希望の凡例を作成できない場合がある。
オープンソースの [ggplot2 book](https://ggplot2-book.org/) [@wickham_ggplot2_2016] や、**ggrepel** や **tidygraph** などの多数の '**gg**package' の説明の中に、良い追加リソースがある。

最初に **sf**、**terra**、**ggplot2** パッケージを使った地図作成を取り上げたのは、これらのパッケージが非常に柔軟で、様々な静的地図を作成することが可能であることがある。
特定の種類の地図作成パッケージ (次の段落) を取り上げる前に、すでに取り上げた汎用の地図作成パッケージの代替品 (Table \@ref(tab:map-gpkg)) について考えてみる価値がある。



Table: (\#tab:map-gpkg)汎用の地図作成パッケージ

|Package   |Title                                                                          |
|:---------|:------------------------------------------------------------------------------|
|ggplot2   |グラフィックの文法を使って、エレガントなデータビジュアライゼーションを作成する |
|googleway |Google Maps API にアクセスし、データの取得と地図のプロットを行う               |
|ggspatial |ggplot2 用の空間データフレームワーク                                           |
|leaflet   |JavaScript 'Leaflet' ライブラリを使ったインタラクティブウェブ地図を作成        |
|mapview   |R で空間データをインタラクティブに表示                                         |
|plotly    |'plotly.js' からインタラクティブなウェブ画像を作成                             |
|rasterVis |ラスタデータの可視化方法                                                       |
|tmap      |主題図                                                                         |



Table \@ref(tab:map-gpkg) は、さまざまな地図作成パッケージが利用可能であることを示しており、この表に記載されていないものも多数ある。
特に注目すべきは **mapsf** で、コロプレス図、比例シンボル地図、フロー地図など、さまざまな地理的視覚化を生成することができる。
これらは、[`mapsf`](https://cran.r-project.org/package=mapsf/vignettes/mapsf.html)\index{mapsf (package)} vignette に記載されている。

Table \@ref(tab:map-spkg) に示すように、いくつかのパッケージは、特定の地図タイプに焦点を当てている。
地理空間を歪めたカルトグラムの作成、ラインマップの作成、ポリゴンの正六角形グリッドへの変換、複雑なデータを地理的トポロジーを表すグリッド上に可視化し、3 次元表現をするパッケージである。


```
#> Warning: One or more parsing issues, call `problems()` on your data frame for details,
#> e.g.:
#>   dat <- vroom(...)
#>   problems(dat)
```



Table: (\#tab:map-spkg)特定の目的のための地図作成パッケージとその関連する指標。

|Package   |Title                                          |
|:---------|:----------------------------------------------|
|cartogram |R で変形地図 (カルトグラム) を作成             |
|geogrid   |地理空間ポリゴンを通常及び六角形ポリゴンに変換 |
|geofacet  |'ggplot2' 用地理データをファセット化           |
|linemap   |Line 地図                                      |
|tanaka    |陰影起伏図 (田中吉郎法)                        |




しかし、前述のパッケージはいずれも、データ準備や地図作成のアプローチが異なっている。
次の段落では、**cartogram** パッケージ [@R-cartogram]\index{cartogram (package)}  にのみ焦点を当てる。
そのため、[geogrid](https://github.com/jbaileyh/geogrid)\index{geogrid (package)}、 [geofacet](https://github.com/hafen/geofacet)\index{geofacet (package)}、[linemap](https://github.com/rCarto/linemap)\index{linemap (package)}、[tanaka](https://github.com/riatelab/tanaka)\index{tanaka (package)}、[rayshader](https://github.com/tylermorganwall/rayshader)\index{rayshader (package)} のドキュメントを読んで、より詳しく知ることを勧める。

カルトグラムとは、地図変数を表現するために一定の幾何学的な歪みを持たせた地図のことである。
このような地図の作成は、R では **cartogram** を用いることで、連続 (contiguous)・非連続 (non-contiguous) の面積カルトグラム (area cartogram) を作成することが可能である。
これ自体は地図作成パッケージではないが、汎用の地図作成パッケージを使用してプロットできるような歪んだ空間オブジェクトを構築することが可能である。

`cartogram_cont()` 関数は、連続した面積カルトグラムを作成する。
入力として、`sf` オブジェクトと変数名 (列) を受け取る。
さらに、`intermax` 引数 (カルトグラム変換の最大反復回数) を変更することが可能である。
例えば、New Zealand の地域の所得の中央値を連続カルトグラム (Figure \@ref(fig:cartomap1) 右図) で表すと、次のようになる。


``` r
library(cartogram)
nz_carto = cartogram_cont(nz, "Median_income", itermax = 5)
tm_shape(nz_carto) + tm_polygons("Median_income")
```

<div class="figure" style="text-align: center">
<img src="figures/cartomap1-1.png" alt="標準地図 (左) と連続範囲 (右) の比較。" width="100%" />
<p class="caption">(\#fig:cartomap1)標準地図 (左) と連続範囲 (右) の比較。</p>
</div>

**cartogram** では、`cartogram_ncont()` を使用して非連続面積カルトグラムを、`cartogram_dorling()` を使用して円面積カルトグラム (Dorling 法) を作成することもできる。
非連続面積カルトグラムは、提供された重み付け変数に基づいて各面積を縮小することによって作成される。
円面積カルトグラム (Dorling 法) は、重み付け変数に比例した面積を持つ円から構成されている。
以下のコードは、米国各州の人口の非連続面積と円面積カルトグラム (Dorling 法) の作成例である (Figure \@ref(fig:cartomap2))。


``` r
us_states9311 = st_transform(us_states, "EPSG:9311")
us_states9311_ncont = cartogram_ncont(us_states9311, "total_pop_15")
us_states9311_dorling = cartogram_dorling(us_states9311, "total_pop_15")
```

<div class="figure" style="text-align: center">
<img src="figures/cartomap2-1.png" alt="非連続領域カルトグラム (左) と円面積カルトグラム (右) の比較。" width="100%" />
<p class="caption">(\#fig:cartomap2)非連続領域カルトグラム (左) と円面積カルトグラム (右) の比較。</p>
</div>

## 演習


ここでの演習は、新しくオブジェクト `africa` を使用する。
これは、**spData** のデータセット `world` と `worldbank_df` から、以下のように作成する。

``` r
library(spData)
africa = world |> 
  filter(continent == "Africa", !is.na(iso_a2)) |> 
  left_join(worldbank_df, by = "iso_a2") |> 
  select(name, subregion, gdpPercap, HDI, pop_growth) |> 
  st_transform("ESRI:102022") |> 
  st_make_valid() |> 
  st_collection_extract("POLYGON")
```

**spDataLarge** のデータセット `zion` と `nlcd` も使用する。

``` r
zion = read_sf((system.file("vector/zion.gpkg", package = "spDataLarge")))
nlcd = rast(system.file("raster/nlcd.tif", package = "spDataLarge"))
```

E1. **graphics** (ヒント: `plot()`) と **tmap** パッケージ (ヒント: `tm_shape(africa) + ...`) を使って、Africa 全土の人間開発指数 (`HDI`) の地理的分布を示す地図を作成しなさい。

- それぞれの長所を経験に基づいて 2 つ挙げなさい。
- 他の地図作成パッケージを 3 つ挙げ、それぞれの利点を挙げなさい。
- ボーナス: これら 3 つの他のパッケージを使って、さらに 3 つのアフリカの地図を作りなさい。



E2. 前の演習で作成した **tmap** を拡張して、凡例に 3 つのビンを設定しなさい: "High" (0.7 を超える `HDI`)、"Medium" (0.55 と 0.7 の間の `HDI`)、"Low" (0.55 を下回る `HDI`)。
- ボーナス: 例えば、凡例のタイトル、クラスラベル、色パレットを変更することで、マップの美観を改善しなさい。



E3. `africa` の小地域を地図上に表示しなさい。
デフォルトの色パレットと凡例のタイトルを変更しなさい。
次に、この地図と前の練習で作成した地図を組み合わせて、一つのプロットし統合しなさい。



E4. Zion 国立公園の土地被覆マップを作成しなさい。

- 土地被覆カテゴリの認識に合わせてデフォルトの色を変更
- 縮尺バーと北矢印を追加し、両方の位置を変更して地図の美観を向上
- ボーナス: Zion 国立公園の Utah 州との位置関係を示す挿入地図を追加 (ヒント: ユタを表すオブジェクトは `us_states` データセットから抽出できる)。





E5. Eastern Africa の国々のファセットマップを作成しなさい。

- 1 つのファセットは HDI を表し、もう 1 つのファセットは人口増加を表す (ヒント: それぞれ変数`HDI`と`pop_growth`を使用)
- 国ごとに「小さな倍数」を設定



E6. これまでのファセット地図の例に基づいて、East Africa の地図アニメーションを作成しなさい。

- 各国を順番に表示
- HDI を示す凡例とともに各国を順番に表示



E7. Africa における HDI のインタラクティブ地図を作成しなさい。

- **tmap**
- **mapview**
- **leaflet**
- ボーナス: 各アプローチについて、凡例 (自動的に提供されない場合) とスケールバーを追加しなさい。



E8. 交通政策や土地利用政策をよりエビデンスに基づいたものにするために使用できるウェブ地図アプリのアイデアを紙にスケッチしなさい。

  - あなたが住んでいる都市で、1 日あたり数人のユーザー向け
  - あなたが住んでいる国で、1 日あたり数十人のユーザー向け
  - 世界中、1 日あたり数百人のユーザーと大規模なデータ配信が必要な場合



E9. `coffeeApp/app.R` のコードを更新し、Brazil を中心に表示するのではなく、ユーザーがどの国を中心に表示するかを選択しなさい。

- `textInput()` を使いなさい
- `selectInput()` を使いなさい



E10. **ggplot2** パッケージを使用して、Figure 9.1 と Figure 9.7 をできるだけ忠実に再現しなさい。



E11. `us_states` と `us_states_df` を結合し、新しいデータセットを使って各州の貧困率を計算しなさい。
次に、総人口に基づいて連続的な範囲カートグラムを作成しなさい。
最後に、貧困率の 2 つの地図を作成し、比較しなさい：(1) 標準的なコロプレス地図と、(2) 作成したカートグラムの境界線を使った地図。
1 枚目と 2 枚目の地図から得られる情報は何か?
両者はどう違うのか?



E12. Africa の人口増加を視覚化しなさい。
次に、**geogrid** パッケージを使って作成した六角形と正方形のグリッドの地図と比較しなさい。

# 地理データの再投影  {#reproj-geo-data}



## 必須パッケージ  {- #prerequisites-07}

- この章では、以下のパッケージが必要である。


``` r
library(sf)
library(terra)
library(dplyr)
library(spData)
library(spDataLarge)
```

## イントロダクション  {#reproj-intro}

Section \@ref(crs-intro) では、座標参照系 (CRS) を紹介し、<u>地理座標系</u> ('lon/lat'、単位は経度と緯度) と<u>投影座標系</u> (通常は基準点からのメートル) という 2 つの主要なタイプに焦点を当てた。
この章では、その知識をもとに、さらに踏み込んだ内容になっている。
具体的には、ある CRS から別の CRS に地理データを設定し、<u>変換</u>する方法を説明する。特にデータが緯度経度座標の場合、CRS を無視することによって発生し得る問題があるので、これを明らかにして注意を促したい。
\index{CRS!ちりてき@地理的} 
\index{CRS!とうえい@投影} 

多くのプロジェクトでは、CRS について心配する必要はないし、変換について考える必要もない。
しかし、データが投影座標参照系なのか地理座標参照系なのか、そしてそれがジオメトリ操作に与える影響を知ることは重要である。
この情報を知っていれば、CRS は裏で<u>ただ</u>うまく機能してくれる。しかし、うまくいかないことがあったとき、CRS に原因があるかもしれず、突然 CRS について学ぶ必要が出てくるのである。
すべての投影データが入る CRS を明確に定義し、異なる CRS をどのように、そしてなぜ使うのかを理解することで、物事がうまくいくことを確実にすることができる。
さらに、座標系について学ぶことで、地理データセットとその効果的な使用方法についての知識を深めることができる。

この章では、CRS の基本を学び、異なる CRS を使用した場合の結果 (何が問題になるかを含む) を示し、ある座標系から別の座標系にデータセットを「再投影」する方法について説明する。
次のセクションでは R における CRS を紹介し、続いて Section \@ref(crs-setting) で空間オブジェクトに関連する CRS の取得と設定方法を示す。 
Section \@ref(geom-proj) は、バッファを作成する作業例を参照しながら、データがどの CRS にあるのかを知ることの重要性を示している。
Section \@ref(whenproject) と Section \@ref(which-crs) において、それぞれ、いつ再投影するべきか、どの CRS を使うかという問題に取り組んでいる。
最後に、ベクタとラスタの再投影については、Section \@ref(reproj-vec-geom) と Section \@ref(reproj-ras) で、地図投影の修正については Section \@ref(mapproj) で説明する。

## 座標参照系  {#crs-in-r}

\index{CRS!EPSG}
\index{CRS!WKT}
\index{CRS!proj-string}
R-spatial のコアパッケージや QGIS などのデスクトップ GIS ソフトウェアなど、CRS 変換を必要とする最新の地理ツールのほとんどは、「ある座標参照系 (CRS) から別の座標に変換する」オープンソース C++ ライブラリ [PROJ](https://proj.org) とつながっている。
CRS には、以下のような様々な表現方法がある。

1. 単純だが曖昧になる可能性のある記述、例えば「lon/lat座標で表示される」
2. `+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs` のような、形式化された、しかし今では時代遅れの「proj4 文字列」(または proj-string)
3. `EPSG:4326` のような識別用の 'authority:code' テキスト文字列

上の例はそれぞれ、全地球測位システム (Global Positioning System, GPS) 座標やその他多くのデータセットの基礎となる「WGS84」座標系という同じものを指している。(訳注: WGS84 は、世界で一般的に用いられている緯度経度座標系だが、日本の場合は、JGD2011 が用いられることが多い。そのコードは `EPSG:6668` である。なお、JGD2011 は東日本大震災の影響を考慮しており、震災以前は `JGD2000` が用いられていた。そのコードは `EPSG:4612` である。データが作成された年によって両者を使い分けるとよい。詳細については、[空間情報クラブ](https://club.informatix.co.jp/?p=998)などを参照。)
しかし、どれが正しいのだろうか？

\index{CRS!EPSG}
一言でいうと、第三の CRS 識別方法が正しい。`EPSG:4326` は、本書で取り上げる **sf** と **terra**  (さらに **stars**) パッケージ、及び [QGIS](https://docs.qgis.org/3.16/en/docs/user_manual/working_with_projections/working_with_projections.html) や [PROJ](https://proj.org/development/quickstart.html) など地理データを扱う多くのソフトウェアプロジェクトが理解できる。
`EPSG:4326` は将来を見据えたものである。
さらに、「EPSG:4326」は、機械可読でありながら、短く覚えやすく、オンラインで非常に「見つけやすい」 (例えば、EPSG:4326 を検索すると、ウェブサイト [epsg.io](https://epsg.io/4326) の専用ページが表示される)。
より簡潔に `4326` だけでも **sf** によって理解されるが、 **曖昧さを防ぎ、文脈を提供するために、より明示的な `AUTHORITY:CODE` という形式を推奨する**。

\index{CRS!WKT}
より長く答えると、3 つの記述のどれも十分ではなく、CRS の処理と変換を明確にするためには、より詳細な情報が必要になる。
このため、Open Geospatial Consortium  (OGC、**sf** パッケージが実装するシンプルフィーチャの仕様も整備している団体) が、WKT (Well-Known Text) と呼ばれる CRS 記述形式をオープンスタンダードで開発した。
これは、「ISO 19111:2019 に記述された座標参照系の抽象モデルのテキスト文字列実装の構造と内容を定義する」[100ページを超えるドキュメント](https://portal.opengeospatial.org/files/18-010r7)に詳細が記述されている。 [@opengeospatialconsortium_wellknown_2019]。
WGS84 CRS、**識別子** `EPSG:4326` の WKT 表現は以下の通りである。


``` r
st_crs("EPSG:4326")
#> Coordinate Reference System:
#>   User input: EPSG:4326 
#>   wkt:
#> GEOGCRS["WGS 84",
#>     ENSEMBLE["World Geodetic System 1984 ensemble",
#>         MEMBER["World Geodetic System 1984 (Transit)"],
#>         MEMBER["World Geodetic System 1984 (G730)"],
#>         MEMBER["World Geodetic System 1984 (G873)"],
#>         MEMBER["World Geodetic System 1984 (G1150)"],
#>         MEMBER["World Geodetic System 1984 (G1674)"],
#>         MEMBER["World Geodetic System 1984 (G1762)"],
#>         MEMBER["World Geodetic System 1984 (G2139)"],
#>         ELLIPSOID["WGS 84",6378137,298.257223563,
#>             LENGTHUNIT["metre",1]],
#>         ENSEMBLEACCURACY[2.0]],
#>     PRIMEM["Greenwich",0,
#>         ANGLEUNIT["degree",0.0174532925199433]],
#>     CS[ellipsoidal,2],
#>         AXIS["geodetic latitude (Lat)",north,
#>             ORDER[1],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>         AXIS["geodetic longitude (Lon)",east,
#>             ORDER[2],
#>             ANGLEUNIT["degree",0.0174532925199433]],
#>     USAGE[
#>         SCOPE["Horizontal component of 3D system."],
#>         AREA["World."],
#>         BBOX[-90,-180,90,180]],
#>     ID["EPSG",4326]]
```

\index{CRS!SRID}
コマンドの出力は、CRS 識別子 (空間参照識別子または Spatial Reference Identifier [SRID](https://postgis.net/workshops/postgis-intro/projection.html) とも呼ばれる) がどのように機能するかを示している。これは単にルックアップであり、CRS のより完全な WKT 表現に関連する一意の識別子を提供するものである。
このことは、識別子と CRS の長い WKT 表現との間にミスマッチがある場合はどうなるのか、という問題を提起している。
この点、@opengeospatialconsortium_wellknown_2019 は明確で、冗長な WKT 表現が[識別子](https://docs.ogc.org/is/18-010r7/18-010r7.html#37)より優先される。 

> 引用された識別子の属性や値が、WKT 記述で明示的に与えられた属性や値と矛盾する場合、 WKT の値が優先されるものとする。

\index{CRS!SRID}
CRS の識別子を `AUTHORITY:CODE` という形式で参照する慣習は、他の[言語](https://jorisvandenbossche.github.io/blog/2020/02/11/geopandas-pyproj-crs/)で書かれた地理ソフトウェアでも使われており、正式に定義された広範囲の座標系を参照することができる。^[
[QGIS](https://docs.qgis.org/3.16/en/docs/pyqgis_developer_cookbook/crs.html?highlight=srid) は、5つの識別子タイプ (EPSGコード、PostGIS SRID、INTERNAL SRID、PROJ 文字列、WKT 文字列) や、`EPSG:4326` 識別子のより長い表現である `urn:ogc:def:crs:EPSG::4326` も受け入れ可能で、固有の CRS を参照する [@opengeospatialconsortium_wellknown_2019]。
]
CRS の識別子で最もよく使われる機関は、CRS の標準化リストを発表した欧州石油調査グループ (European Petroleum Survey Group) の頭文字をとった *EPSG*\index{CRS!EPSG} である (EPSG は2005年に石油・ガス団体の [Geomatics Committee of the International Association of Oil & Gas Producers](https://epsg.org/home.html) により[引き継ぎ](http://wiki.gis.com/wiki/index.php/European_Petroleum_Survey_Group)された)。
CRS の識別子には、他の機関を使用することもできる。
例えば、`ESRI:54030` は、ESRI の Robinson 投影の実装で、以下の WKT 文字列 (最初の8行のみ表示) を持っていることを指している。


``` r
st_crs("ESRI:54030")
#> Coordinate Reference System:
#>   User input: ESRI:54030 
#>   wkt:
#> PROJCRS["World_Robinson",
#>     BASEGEOGCRS["WGS 84",
#>         DATUM["World Geodetic System 1984",
#>             ELLIPSOID["WGS 84",6378137,298.257223563,
#>                 LENGTHUNIT["metre",1]]],
....
```



\index{CRS!WKT}
WKT 文字列は網羅的で詳細かつ正確であるため、CRS の格納や変換を曖昧にすることなく行うことができる。
測地系 (datum)、楕円体 (ellipsoid)、本初子午線、投影法 (projection)、単位 (unit) など、任意の CRS に関するすべての関連情報が含まれている。^[
WKT の CRS 定義が登場する以前は、proj-string が座標操作の指定と CRS の保存の標準的な方法であった。
この文字列表現は、key=value の形式 (例えば、`+proj=longlat +datum=WGS84 +no_defs`) で構築されている。すでに WKT 表現に取って代わられたか、将来的に代えられることが多いはずである。
]

\index{CRS!proj-string}
最近 (ver 6 以降) の PROJ のバージョンでは、座標操作を定義するために proj-string を使用することができるが、いくつかの proj-string キー (`+nadgrids` , `+towgs84` , `+k` , `+init=epsg:`) はもうサポートされていないか、推奨されないものである。
また、proj-string に直接設定できる測地基準系 (datum) は 3 つ (WGS84、NAD83、NAD27) だけである。
CRS の定義の進化と PROJ ライブラリの長い説明は、@bivand_progress_2021、@pebesma_spatial_2022 の第 2 章、Floris Vanderhaeghe によるブログ ([https://inbo.github.io/tutorials/tutorials/spatial_crs_coding/](https://inbo.github.io/tutorials/tutorials/spatial_crs_coding/)) に記載されている。
[PROJ documentation](https://proj.org/development/reference/cpp/cpp_general.html) にも概説されているように、WKT CRS 形式には WKT1 と 2 種類の WKT2 があり、後者 (WKT2, 2018 仕様) は ISO 19111:2019 に対応するものである [@opengeospatialconsortium_wellknown_2019]。

## 座標系の照会と設定  {#crs-setting}

\index{べくた@ベクタ!CRS}
R の空間オブジェクトに CRS がどのように格納され、どのようにクエリや設定ができるのかを見ていこう。
まず、**ベクタ**の地理データオブジェクトの CRS の取得と設定について、次の例から見ていく。


``` r
vector_filepath = system.file("shapes/world.gpkg", package = "spData")
new_vector = read_sf(vector_filepath)
```

新しいオブジェクトである `new_vector` は、世界の国々を表すクラス `sf` のデータフレームである (詳しくはヘルプページ `?spData::world` を参照)。
CRS は **sf** 関数 `st_crs()` で取得することができる。


``` r
st_crs(new_vector) # get CRS
#> Coordinate Reference System:
#>   User input: WGS 84 
#>   wkt:
#>   ...
```



\index{べくた@ベクタ!CRS}
出力は主に2つの要素を含むリストである。

1. `User input` (この場合、`WGS 84`、入力ファイルから取得した `EPSG:4326` の同義語)、前述の CRS 識別子に対応する。
2. `wkt` CRS に関するすべての関連情報を含む完全な WKT 文字列を含む。

`input` 要素は柔軟性があり、入力ファイルやユーザー入力に応じて、`AUTHORITY:CODE` 表現 (例: `EPSG:4326`)、CRS の名前 (例: `WGS 84`)、あるいは proj-string 定義を含めることができる。
`wkt` 要素には WKT 表現が格納され、オブジェクトをファイルに保存したり、座標演算を行う際に使用される。
上記で、`new_vector` のオブジェクトは、WGS84 楕円体を持ち、グリニッジ本初子午線を使用し、緯度・経度軸の順番になっていることがわかる。
この場合、この CRS の使用に適したエリアを説明する `USAGE` や、CRS の識別子を示す `ID` (`EPSG:4326`) などの追加要素もある。

\index{べくた@ベクタ!CRS}
また、`st_crs` 関数には、使用中の CRS に関する追加情報を取得することができる、という便利な特徴もある。 
例えば、以下を実行してみよう。

- `st_crs(new_vector)$IsGeographic`: CRS が地理的かどうかを確認
- `st_crs(new_vector)$units_gdal`: CRS 単位を調べる
- `st_crs(new_vector)$srid`: その「SRID」識別子を抽出 (存在する場合)
- `st_crs(new_vector)$proj4string`: proj-string 表現を抽出

CRS がない場合や間違った CRS が設定されている場合は、`st_set_crs()` 関数を使用することができる (この場合、ファイル読み込み時にすでに CRS が正しく設定されているので、WKT 文字列は変更されずに残る)。


``` r
new_vector = st_set_crs(new_vector, "EPSG:4326") # CRS を設定
```



\index{らすた@ラスタ!CRS}
ラスタ地理データオブジェクトの CRS の取得と設定は、同様の方法で行われる。
`terra` パッケージの `crs()` 関数は `SpatRaster` オブジェクトから CRS 情報にアクセスする (読みやすく表示するために `cat()` 関数を使用していることに注意)。 


``` r
raster_filepath = system.file("raster/srtm.tif", package = "spDataLarge")
my_rast = rast(raster_filepath)
cat(crs(my_rast)) # CRS を取得
#> GEOGCRS["WGS 84",
#>     DATUM["World Geodetic System 1984",
#>         ELLIPSOID["WGS 84",6378137,298.257223563,
#>             LENGTHUNIT["metre",1]]],
#>     PRIMEM["Greenwich",0,
#>         ANGLEUNIT["degree",0.0174532925199433]],
....
```

出力は CRS の WKT 表現である。 
同じ関数、`crs()` を使って、ラスタオブジェクトに CRS を設定することもできる。


``` r
crs(my_rast) = "EPSG:26912" # CRS を設定
```

ここでは、識別子 (ほとんどの場合こちらを推奨) または完全な WKT 表現のいずれかを使用することができる。
`crs` を設定する代替方法としては、proj-string 文字列または `crs()` を持つ他の既存のオブジェクトから抽出された CRS があるが、これらのアプローチは将来対応されない可能性がある。

重要な点として、`st_crs()` と `crs()` 関数は、座標の値や形状を変更しない。
その役割は、オブジェクト CRS のメタデータ情報を設定することのみである。

Section \@ref(vector-data) で紹介したロンドンの例を基に、以下のコードで作成した `london` データセットのように、地理的オブジェクトの CRS が不明な場合がある。


``` r
london = data.frame(lon = -0.1, lat = 51.5) |> 
  st_as_sf(coords = c("lon", "lat"))
st_is_longlat(london)
#> [1] NA
```

この出力 `NA` は、**sf** が CRS が何であるかを知らず、推測するつもりがないことを示している (`NA` は、"Not Applicable/Available" の略語で、文字通り「利用できない」という意味)。
CRS を手動で指定するか、CRS メタデータを持つソースから読み込まれない限り、**sf** は座標系について「わからない」と言う以外の明示的な仮定をしない。
この動作は、利用可能な CRS の多様性を考えると理にかなっているが、GeoJSON ファイル形式仕様のような、すべての座標が lon/lat CRS (`EPSG:4326`) を持つという単純化した仮定をするいくつかのアプローチとは異なる。
すべての地理座標には座標参照系があり、ソフトウェアがプロットやジオメトリの操作を正しく判断できるのは、扱う CRS の種類がわかっている場合のみである。
したがって、データセットの CRS を常に確認し、不足している場合は設定することが重要である。


``` r
london_geo = st_set_crs(london, "EPSG:4326")
st_is_longlat(london_geo)
#> [1] TRUE
```

## 投影データおよび非投影データに対する幾何学操作  {#geom-proj}

**sf** version 1.0.0 より、R は緯度経度 CRS を持って入るベクタデータセットに対する機能が大幅に強化された。この機能強化は、Section \@ref(s2) で取り上げた S2 <u>球面ジオメトリエンジン</u>によるものである。
Figure \@ref(fig:s2geos) で示すように、**sf** は、CRS 種別に応じて GEOS\index{GEOS} または S2\index{S2} を使い分ける (デフォルトは S2)。^[`st_area()` 関数は例外。`sf_use_s2()` がオフの時、地理的 CRS データの面積計算には、**lwgeom** の `st_geod_area()` 関数を使用する。]
座標投影系のデータと CRS がないデータの場合、常に GEOS が使われる。地理データではデフォルトで S2 が使われるが、無効化したい場合は `sf::sf_use_s2(FALSE)` とする。

<div class="figure" style="text-align: center">
<img src="images/07-s2geos.png" alt="入力データの CRS に依存する sf パッケージのジオメトリ操作の動作。" width="100%" />
<p class="caption">(\#fig:s2geos)入力データの CRS に依存する sf パッケージのジオメトリ操作の動作。</p>
</div>

CRS の重要性を示すために、このセクションでは、前セクションで作成した `london` オブジェクトの周りに 100 km のバッファを作成する。
また、100 km にほぼ相当する 1 度 (赤道では 1 度は約 111 km) の「距離」を持つ意図的に欠陥のあるバッファを作成する。
コードに入る前に、Figure \@ref(fig:crs-buf) を見て、これからコードチャンクで再現するはずの出力を視覚的に把握するのもよいだろう。

最初の段階として、上記で作成した `london` と `london_geo` のオブジェクトの周りに、ロンドン中心部から1度と 100 km (または 10万 m、科学的表記法では `1e5` と表現できる) の境界距離の3つのバッファを作成する。


``` r
london_buff_no_crs = st_buffer(london, dist = 1)  # 正しくない: CRS がない
london_buff_s2 = st_buffer(london_geo, dist = 100000) # 暗黙で s2 を使用
london_buff_s2_100_cells = st_buffer(london_geo, dist = 100000, max_cells = 100) 
```

上の1行目では、**sf** は入力が投影されていると仮定して、度数単位のバッファを持つ結果を生成しているが、後述するようにこれは問題である。
2 行目の **sf** では、Chapter \@ref(spatial-class) で導入された球面幾何エンジン S2 明示せずに使用し、`max_cells = 1000` のデフォルト値 (3 行目で `100` に設定) を使用してバッファの範囲を計算しているが、その結果はすぐに明らかになるだろう。
非投影 (地理) 座標系に対する **sf** の S2\index{S2} 幾何エンジン使用の影響を強調するために、以下のコードチャンクで、コマンド `sf_use_s2()` (デフォルトではオン、`TRUE`) で一時的にそれを無効にしてみよう。
`london_buff_no_crs` と同様、新しい `london_geo` オブジェクトは、単位が度でほとんどの場合意味を持たない。


``` r
sf::sf_use_s2(FALSE)
#> Spherical geometry (s2) switched off
london_buff_lonlat = st_buffer(london_geo, dist = 1) # 正しくない結果
#> Warning in st_buffer.sfc(st_geometry(x), dist, nQuadSegs, endCapStyle =
#> endCapStyle, : st_buffer does not correctly buffer longitude/latitude data
#> dist is assumed to be in decimal degrees (arc_degrees).
sf::sf_use_s2(TRUE)
#> Spherical geometry (s2) switched on
```

上記の警告メッセージは、lon/lat データに対して平面ジオメトリ演算を実行する際の問題を示唆している。 
球形幾何演算をコマンド (`sf::sf_use_s2(FALSE)`) でオフにすると、バッファ (およびその他のジオメトリ演算) は緯度と経度の単位を使用するため、メートルなどの適切な距離単位の代わりにならないため、価値のない出力となる場合がある。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">子午線と呼ばれる 2 本の経線間の距離は、赤道では約 111 km である (正確な距離は `geosphere::distGeo(c(0, 0), c(1, 0))` を実行して調べられる)。\index{しごせん@子午線}
これは極点でゼロに縮まる。
例えば、ロンドンの緯度では、子午線の距離は 70 km 以下である (課題: これを検証するコードを実行しなさい)。
<!-- `geosphere::distGeo(c(0, 51.5), c(1, 51.5))` -->
一方、緯度線は緯度に関係なく等距離にあり、赤道や極付近を含めて常に 111 km 程度の間隔がある (Figure \@ref(fig:crs-buf) から Figure \@ref(fig:wintriproj)参照)。</div>\EndKnitrBlock{rmdnote}

地理的 (緯度経度) CRS に関する警告は「CRS を設定してはいけない」という解釈をするべきではない。むしろ、ほとんど常に設定すべきである。
これは、投影された CRS にデータを<u>再投影</u>することを提案したと理解するのがよいだろう。
ただし、この提案に常に耳を傾ける必要もない。空間演算と幾何演算を実行しても、ほとんど違いがない場合もある (例えば、空間的な部分集合作成など)。
しかし、バッファ作成など距離を伴う操作では、(球面幾何エンジンを使わずに) 良い結果を得るには、データの投影コピーを作成し、それに対して操作を実行するしかない。
これは、以下のコードチャンクで行われる。


``` r
london_proj = data.frame(x = 530000, y = 180000) |> 
  st_as_sf(coords = c("x", "y"), crs = "EPSG:27700")
```

結果は、`london` と同じであるが、適切な CRS (この場合、EPSG コードが 27700 の British National Grid) で、単位がメートルである新しいオブジェクトが作成される。
CRS が変化したことは、`st_crs()` を使って次のように確認できる (出力の一部は `...` で置き換えている)。


``` r
st_crs(london_proj)
#> Coordinate Reference System:
#>   User input: EPSG:27700 
#>   wkt:
#> PROJCRS["OSGB36 / British National Grid",
#>     BASEGEOGCRS["OSGB36",
#>         DATUM["Ordnance Survey of Great Britain 1936",
#>             ELLIPSOID["Airy 1830",6377563.396,299.3249646,
#>                 LENGTHUNIT["metre",1]]],
....
```

この CRS の記述で注目すべきは、EPSG コード (`EPSG: 27700`) と詳細な `wkt` の文字列 (最初の5行のみ表示) であろう。^[
最も関連性の高い投影パラメータと関連する概念の簡単な説明については、Jochen Albrecht による第4回講演を参照。
http://www.geography.hunter.cuny.edu/~jochen/GTECH361/lectures/ および https://proj.org/usage/projections.html に情報がある。
]
LENGTHUNIT フィールドに記述された CRS の単位が (度ではなく) メートルであることから、これが投影型 CRS であることがわかる。 `st_is_longlat(london_proj)` は現在 `FALSE` を返し、`london_proj` に対する幾何演算は警告なしで機能する。
`london_proj` のバッファ操作は GEOS を使用し、結果は適切な距離の単位で返される。
次のコードは、ちょうど 100 km の<u>投影</u>データの周りにバッファを作成するものである。


``` r
london_buff_projected = st_buffer(london_proj, 100000)
```

先に作成した CRS を<u>持つ</u> 3 つの `london_buff*` オブジェクト (`london_buff_s2`、`london_buff_lonlat`、`london_buff_projected`) の形状を Figure \@ref(fig:crs-buf) に示す。



<div class="figure" style="text-align: center">
<img src="figures/crs-buf-1.png" alt="London 周辺のバッファで、S2 球面幾何エンジンを用いて作成した緯度経度データ (左)、投影データ (中)、球面幾何を用いない緯度経度データ (右) の結果を示している。左のプロットは、投影されていないデータを sf でバッファ作成した結果を示しており、デフォルトで Google の S2 spherical geometry engine を max_cells を 1000 に設定して呼び出している (細線)。太い「ブロック状の」線は、max_cells を 100 に設定して同じ操作を行った結果を示している。" width="100%" />
<p class="caption">(\#fig:crs-buf)London 周辺のバッファで、S2 球面幾何エンジンを用いて作成した緯度経度データ (左)、投影データ (中)、球面幾何を用いない緯度経度データ (右) の結果を示している。左のプロットは、投影されていないデータを sf でバッファ作成した結果を示しており、デフォルトで Google の S2 spherical geometry engine を max_cells を 1000 に設定して呼び出している (細線)。太い「ブロック状の」線は、max_cells を 100 に設定して同じ操作を行った結果を示している。</p>
</div>

`s2` と適切に予測された CRS に基づくバッファは、バッファの境界のすべての部分が London から等距離にあることを意味し、「つぶされた」ものではないことは、Figure \@ref(fig:crs-buf) から明らかである。
入力に CRS がないか、`sf_use_s2()` がオフになっているため、`s2` が<u>使われていない</u>ときに緯度経度 CRS から生成される結果は、南北軸に細長く歪んでいる。緯度経度に投影データを仮定する (GEOS による) アルゴリズムを使うことが危険であることが明らかである。
しかし、S2\index{S2} で生成された結果も、劇的な変化はないものの、歪んでいる。
Figure \@ref(fig:crs-buf) (左) のバッファ境界はどちらもギザギザしているが、これは `s2` の引数 `max_cells` を 100 に設定して作成したバッファを表す太い境界の場合のみ、明らかまたは関連性があると考えられる。
S2 経由の緯度経度データから得られる結果は、投影データから得られる結果とは異なるという教訓である。
投影データにおける S2\index{S2} 由来のバッファと GEOS\index{GEOS} 由来のバッファの差は、`max_cells` の値が大きくなるほど小さくなる。この引数の「正しい」値は多くの要因に依存すると思われるが、デフォルト値 1000 は妥当なデフォルト値だと思われる。
`max_cells` の値を選択する時、計算の速度と結果の解像度のバランスをとる必要がある。
滑らかな曲線の境界が有利な場合、バッファ作成 (または他のジオメトリ操作) の前に投影型 CRS に変換することが適切な場合がある。

CRS の重要性 (投影座標か地理座標か) と、緯度経度に対してバッファ作成する際に S2 を使用するという **sf** のデフォルト設定がデータに与える影響は、上記の例から明らかである。
この後のセクションでは、投影 CRS が必要な場合にどの CRS を使用するか、ベクタおよびラスタオブジェクトの再投影の詳細について、より深く掘り下げて説明する。

## いつ再投影するべきか？  {#whenproject}

\index{CRS!さいとうえい@再投影} 
前節では、CRS を手動で設定する方法として、`st_set_crs(london, "EPSG:4326")` を紹介した。
しかし、現実のアプリケーションでは、データの読み込み時に自動的に CRS が設定されるのが一般的である。
多くのプロジェクトで、CRS 関連の主なタスクは、ある CRS から別の CRS に、オブジェクトを<u>変換</u>することである。
しかし、どのような場合にデータを変換する必要があるのだろうか。 
そして、どの CRS に？
こういった質問に対する明確な答えはなく、CRS の選択には常にメリットだけでなくデメリットもある [@maling_coordinate_1992]。
このセクションでは、決定する際に役立つ一般原則を紹介しよう。 

まず最初に、<u>いつ変換するべきか</u>を考える。
**leaflet** パッケージでデータをオンライン公開する場合など、地理的 CRS が必要になる。
また、異なる CRS を持つ2つのオブジェクトの距離を求める場合のように、異なる CRS を持つ 2 つの `sf` オブジェクトを比較したり、組み合わせたりする必要がある場合もある。


``` r
st_distance(london_geo, london_proj)
# > Error: st_crs(x) == st_crs(y) is not TRUE
```

`london` と `london_proj` のオブジェクトを地理的に比較できるようにするには、一方を他方の CRS に変換する必要がある。
しかし、どの CRS を使えばいいのか？
特にウェブマッピングを含む多くのプロジェクトでは、EPSG:4326 での出力が必要であるが、その場合、投影オブジェクトを変換する価値がある。
しかし、球面幾何演算エンジンではなく平面ジオメトリ演算が必要なプロジェクト (例えば、滑らかなエッジを持つバッファを作成する) の場合、地理的 CRS のデータを英国ナショナルグリッド (EPSG:27700) などの投影 CRS で同等のオブジェクトに変換する価値があるだろう。
それが、Section \@ref(reproj-vec-geom) のテーマである。

## どの CRS を使うべきか？  {#which-crs}

\index{CRS!さいとうえい@再投影} 
\index{とうえい@投影!せかいそくちけい@世界測地系}
どの CRS を使うかというのは難しい問題で、「正しい」答えがあるわけではない。
「万能の投影は存在せず、すべて指定したフレームの中心から離れると歪みが発生する」 [@bivand_applied_2013] 。
さらに言えば、すべてのタスクで 1 つの投影法だけに執着するべきではない。
ある投影法を解析の一部に使い、別の投影法を別の部分に使い、さらに別の投影法を可視化することも可能である。
常に自分の目標に最も適した CRS を選ぶように心がけよう。

**地理的 CRS**\index{CRS!ちりてき@地理的} を選択する場合、[WGS84](https://en.wikipedia.org/wiki/World_Geodetic_System#A_new_World_Geodetic_System:_WGS_84)  ([日本語](https://ja.wikipedia.org/w/index.php?curid=52196) 版) となることが多い。(訳注: 上で既に述べたが、WGS84 に対応する日本の CRS は、東日本大震災以降の JGD2011 と、それ以前の JGD2000 である。大事なことなので繰り返す。)
ウェブマッピングだけでなく、GPS データセットや何千ものラスタ、ベクタデータセットがこの CRS でデフォルトで提供されているため、利用されている。
WGS84 は世界で最も一般的な CRS なので、その EPSG コード 4326 を知っておくとよいだろう。(訳注: JGD2011は 6668、JGD2000 は 4612 である。)^[
`"EPSG:4326"` の代わりに、`"OGC:CRS84"` を使うこともできる。前者では、経度の前に緯度が並べ替えられる。後者は、GeoJSON の標準形式であり、緯度の前に経度が並べ替えられる。]
この「マジックナンバー」は、投影された CRS が異常なオブジェクトを、広く理解されるものに変換するために使用することができる。

**投影 CRS**\index{CRS!とうえい@投影} が必要な場合はどうだろうか？
自由に決められないこともある。
「多くの場合、投影の選択は公的な地図作成機関によって行われる」 [@bivand_applied_2013] 。
つまり、現地のデータソースで作業する場合、公式の CRS が最も正確ではないとしても、互換性を確保するために、データが提供された CRS で作業することが望ましいと思われる。
London の例は、(a) 英国ナショナルグリッド (関連する EPSG コード27700) がよく知られており、(b) 元のデータセット (`london`) がすでにその CRS を持っていたので、簡単に答えることができたのである。

\index{UTM} 
一般的に使われているデフォルトは Universal Transverse Mercator ([UTM](https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system) [日本語](https://ja.wikipedia.org/w/index.php?curid=118035)) で、地球を縦 60 個のくさびと横 20 個の緯度に分割した CRS のセットである。
地球上のほとんどの場所には UTM コードがあり、例えば「60H」 は R が発明された New Zealand 北部を指している。
UTM EPSG コードは、北半球では 32601 から 32660 まで、南半球では 32701 から 32760 まで順次表示される。

その仕組みを説明するために、 [ここにある通り](https://stackoverflow.com/a/9188972/)、地球上の任意の地点に関連する EPSG コードを計算する関数 `lonlat2UTM()` を作ってみよう。 


``` r
lonlat2UTM = function(lonlat) {
  utm = (floor((lonlat[1] + 180) / 6) %% 60) + 1
  if (lonlat[2] > 0) {
    utm + 32600
  } else{
    utm + 32700
  }
}
```

次のコマンドは、この機能を利用して、Auckland と London の UTM ゾーンと関連する EPSG コードを特定する。




``` r
lonlat2UTM(c(174.7, -36.9))
#> [1] 32760
lonlat2UTM(st_coordinates(london))
#> [1] 32630
```

UTM CRS で使用されている横メルカトル図法は等角 (conformal) であるが、UTM ゾーンの中心から離れるにつれて面積や距離の歪みがひどくなる。
そのため、GIS ソフトウェア Manifold のドキュメントでは、UTM ゾーンを使用するプロジェクトの縦断範囲を中心子午線から 6 度までに制限することを提案している ([manifold.net](https://manifold.net/doc/mfd9/universal_transverse_mercator_projection.htm))。
そのため、UTM は比較的狭い範囲での角度保存を重視する場合にのみ使用することを勧める。

現在、適切な CRS を選択するためのツールも用意されており、これには **crssuggest** パッケージ<!--add ref or docs--> が含まれている。
このパッケージのメイン関数である `suggest_crs()` は、地理的な CRS を持つ空間オブジェクトを受け取り、与えられた領域に使用可能な投影 CRS のリストを返す。^[また、本パッケージでは、CRS 情報を付加していないデータの真の CRS を把握することも可能。] 
もう一つの便利なツールは、選択した場所とタイプに基づいて CRS をリストアップするウェブページ https://jjimenezshaw.github.io/crs-explorer/ である。
重要な注意点: これらのツールは多くの場面で役立つが、適用する前に推奨される CRS の特性を知っておく必要がある。

\index{CRS!かすたむ@カスタム} 
適切な CRS がすぐにわからない場合、CRS の選択は、その後の地図や分析において保存することが最も重要である特性によって決められるべきだろう。
CRS は、等面積、等距離、等角 (形状はそのまま)、またはそれらの妥協点の組み合わせである (Section \@ref(projected-coordinate-reference-systems) 参照)。
ローカルパラメータを持つカスタム CRS を対象地域に合わせて作成し、単一の CRS がすべてのタスクに適合しないプロジェクトでは、複数の CRS を使用することができる。
「測地線計算」は、CRS が適切でない場合の代替手段を提供することができる ([proj.org/geodesic.html](https://proj.org/geodesic.html) を参照)。
どの投影 CRS を使っても、数百キロメートルに及ぶジオメトリでは、結果が正確でない可能性がある。

\index{CRS!かすたむ@カスタム}
カスタム CRS を決定する際には、以下を勧める。^[
このアドバイスの基礎となるコメントを下さった匿名の査読者の方に感謝する。
]

\index{とうえいほう@投影法!らんべるとせいせきほういずほう@ランベルト正積方位図法}
\index{とうえいほう@投影法!せいきょほういずほう@正距方位図法}
\index{とうえいほう@投影法!らんべるとせいかくえんすいずほう@ランベルト正角円錐図法}
\index{とうえいほう@投影法!すてれおとうえい@ステレオ投影}
\index{とうえいほう@投影法!ゆにばーさるよこめるかとるずほう@ユニバーサル横メルカトル図法}

- カスタムローカル投影 (原点の緯度・経度を調査地域の中心に設定) のランベルト正積方位図法 (Lambert azimuthal equal-area,  [LAEA](https://en.wikipedia.org/wiki/Lambert_azimuthal_equal-area_projection) [日本語版](https://ja.wikipedia.org/w/index.php?curid=536287))、これはすべての場所で等面積投影だが数千キロメートル以上では形状が歪んでしまう。
- ある地点とローカル投影の中心点との直線距離を具体的に正確に表す正距方位図法 (Azimuthal equidistant, [AEQD](https://en.wikipedia.org/wiki/Azimuthal_equidistant_projection) [日本語版](https://ja.wikipedia.org/w/index.php?curid=40783)) 投影図
- 数千 km に及ぶ地域のランベルト正角円錐図法 (Lambert conformal conic, [LCC](https://en.wikipedia.org/wiki/Lambert_conformal_conic_projection) [日本語版](https://ja.wikipedia.org/w/index.php?curid=536310)) 投影。円錐は、距離と面積の特性がセカント線間で妥当となるように設定されている。
- 極域のステレオ投影 (Stereographic, [STERE](https://en.wikipedia.org/wiki/Stereographic_projection) [日本語版](https://ja.wikipedia.org/w/index.php?curid=1463335)) 投影。ただし、中心から数千キロメートル離れた面積や距離の計算に頼らないように注意すること。

地域のデータセットに特化した投影 CRS を自動的に選択する方法として、調査地域の中心点に対して正距方位図法投影を作成することが考えられる。
これは、データセットの中心点に基づくメートル単位でカスタム CRS (EPSG コードなし) を作成するものである。
他のデータセットが作成したカスタム CRS と互換性がなく、数百キロメートルに及ぶ広範なデータセットに使用すると、結果が正確でなくなる可能性がある。

このセクションで説明する原則は、ベクタデータセットとラスタデータセットに等しく適用される。
しかし、CRS 変換には、それぞれの地理データモデルに特有の特徴がある。
ベクタデータ変換の特殊性は Section \@ref(reproj-vec-geom) で、ラスタ変換の特殊性は Section \@ref(reproj-ras) で説明する。
次に、Section \@ref(mapproj) で、カスタム地図投影を作成する方法を紹介する。

## ベクタジオメトリの再投影  {#reproj-vec-geom}

\index{CRS!さいとうえい@再投影} 
\index{べくた@ベクタ!さいとうえい@再投影} 
Chapter \@ref(spatial-class) は、ベクタ幾何学がいかに点で構成されているか、そしていかに点が直線や多角形などのより複雑なオブジェクトの基礎を形成しているかを示した。
つまり、ベクタの再投影は、直線や多角形の頂点となるこれらの点の座標を変換することになる。

Section \@ref(whenproject) は、2 つのオブジェクト間の距離を計算するために、少なくとも1つの `sf` オブジェクトを異なる CRS を持つ同等のオブジェクトに変換する必要がある例を含んでいる。


``` r
london2 = st_transform(london_geo, "EPSG:27700")
```

`london` の変換版ができたので、**sf** 関数 `st_transform()` を使って、2 つのロンドン表現間の距離を求めることができる。^[
`st_transform()` に代わるものとして、**lwgeom** の `st_transform_proj()` がある。これは、GDAL を使用しない変換を可能にし、GDAL がサポートしていない投影をサポートすることができる。
しかし、本稿執筆時点 (2024年) では、`st_transform_proj()` でサポートされているが、`st_transform()` でサポートされていない投影法を見つけることはできなかった。
]
`london` と `london2` が 2 km 以上も離れているのは意外かもしれない。^[
この 2 点の位置の違いは、変換操作の不完全さ (実際は非常に正確) ではなく、`london` と `london_proj` を作成した手動で作成した座標の精度の低さによるものである。
また、驚くべきは、その結果がメートル単位の行列で提供されていることである。
これは、`st_distance()` が多くのフィーチャ間の距離を提供できることと、CRS の単位がメートルであるためである。
`as.numeric()` を使って、結果を普通の数値型に型強制 (coerce) する。
]


``` r
st_distance(london2, london_proj)
#> Units: [m]
#>      [,1]
#> [1,] 2018
```

CRS の確認と再投影のための関数を、`cycle_hire_osm` を参照して以下に示す。これは **spData** の `sf` オブジェクトで、ロンドンで自転車をレンタルできる「ドッキングステーション」を表しているものである。
Section \@ref(reproj-intro) で学んだように、`sf`オブジェクトの CRS は、関数 `st_crs()` を使って問い合わせることができる。
出力は、以下で示すように座標系に関する情報を複数行のテキストとして表示する。


``` r
st_crs(cycle_hire_osm)
#> Coordinate Reference System:
#>   User input: EPSG:4326 
#>   wkt:
#> GEOGCS["WGS 84",
#>     DATUM["WGS_1984",
#>         SPHEROID["WGS 84",6378137,298.257223563,
....
```

Section \@ref(crs-setting) で見たように、主な CRS コンポーネントである `User input` と `wkt` は単一の実体として出力される。`st_crs()` の出力は、実際には、次のコードチャンクの出力に示すように、`input` と `wkt` という単一の文字列という 2 つの要素を持つクラス `crs` の名前付きリストになっている。


``` r
crs_lnd = st_crs(london_geo)
class(crs_lnd)
#> [1] "crs"
names(crs_lnd)
#> [1] "input" "wkt"
```

`Name`、`proj4string`、`epsg` を含む追加の要素を `$` 演算子で取り出すことができる (詳しくは  [`?st_crs`](https://r-spatial.github.io/sf/reference/st_crs.html)) と GDAL [website](https://gdal.org/tutorials/osr_api_tut.html#querying-coordinate-reference-system) の CRS and tranformation tutorial を参照)。


``` r
crs_lnd$Name
#> [1] "WGS 84"
crs_lnd$proj4string
#> [1] "+proj=longlat +datum=WGS84 +no_defs"
crs_lnd$epsg
#> [1] 4326
```

Section \@ref(crs-in-r) で述べたように、`crs_lnd` オブジェクトの `$wkt` 要素に格納された WKT 表現は、究極の真理の源である。
これは、前のコードチャンクの出力が、オブジェクトとその CRS の固有の属性ではなく、PROJ によって提供される `wkt` 表現からのクエリであることを意味する。

オブジェクトの CRS が変換されると、CRS の `wkt` と `User Input` の両方の要素が変更される。
以下のコードチャンクでは、CRS を投影した新しいバージョンの `cycle_hire_osm` を作成する (簡潔にするため、CRS 出力の最初の 4 行のみを表示する)。


``` r
cycle_hire_osm_projected = st_transform(cycle_hire_osm, "EPSG:27700")
st_crs(cycle_hire_osm_projected)
#> Coordinate Reference System:
#>   User input: EPSG:27700 
#>   wkt:
#> PROJCRS["OSGB36 / British National Grid",
#> ...
```

この結果、オブジェクトは EPSG コード 27700 の新しい CRS を持つことになる。
しかし、この EPSG コードや他のコードの詳細を調べるにはどうしたらよいだろうか？
ネットで検索するのも一つの方法であるが、CRS オブジェクトのプロパティを見ても良い。 


``` r
crs_lnd_new = st_crs("EPSG:27700")
crs_lnd_new$Name
#> [1] "OSGB36 / British National Grid"
crs_lnd_new$proj4string
#> [1] "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000
+y_0=-100000 +ellps=airy +units=m +no_defs"
crs_lnd_new$epsg
#> [1] 27700
```

その結果、EPSG コード 27700 が英国ナショナルグリッドを表しており、「 [EPSG 27700](https://www.google.com/search?q=CRS+27700)」とネット検索すれば出てくるだろう。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">コンソールで空間オブジェクトを表示すると、自動的にその座標参照系が返される。
明示的にアクセスして変更するには、`st_crs()` 関数、例えば `st_crs(cycle_hire_osm)` を使用する。</div>\EndKnitrBlock{rmdnote}

## ラスタジオメトリの再投影  {#reproj-ras}

\index{らすた@ラスタ!さいとうえい@再投影} 
\index{らすた@ラスタ!きかほせい@幾何補正} 
\index{らすた@ラスタ!へんかん@変換} 
\index{らすた@ラスタ!りさんぷりんぐ@リサンプリング} 
前節で説明した投影の概念は、ラスタにも適用できる。
しかし、ベクタとラスタの再投影には重要な違いがある。
ベクタオブジェクトの変換は、すべての頂点の座標を変更することになるが、ラスタデータには当てはまらない。
ラスタは同じ大きさの矩形セル (度やメートルなどの地図単位で表現される) で構成されているため、通常、ピクセルの座標を個別に変換することは不可能である。
よってラスタの再投影では、多くの場合、元のオブジェクトとは異なる列と行の数で、新しいラスタオブジェクトを作成する。
その後、新しいピクセルを適切な値で「埋める」ことができるように、属性を再推定する必要がある。
つまり、ラスタの再投影は、ラスタ範囲を別の CRS にベクタ再投影 (Section \@ref(reproj-vec-geom))、リサンプリングによる新しいピクセル値の計算 (Section \@ref(resampling)) という 2 つの別々の空間処理として考えることができる。
したがって、ラスタデータとベクタデータの両方を使用する場合は、ラスタの再投影を避け、ベクタの再投影を行う方が良い場合がほとんどである。

\BeginKnitrBlock{rmdnote}<div class="rmdnote">通常のラスタの再投影は、幾何補正 (warp) とも呼ばれている。
さらに、似たような操作で「変形」と呼ばれるものが 2 つある。
すべての値をリサンプリングするのではなく、すべての値をそのままに、ラスタセルごとに新しい座標を再計算し、グリッドジオメトリを変更する。
例えば、入力されたラスタ (正方形の格子) を曲線的な格子に変換することができる。
\index{stars (package)}
変換操作は、[**stars** パッケージ](https://r-spatial.github.io/stars/articles/stars5.html)を用いて R で行うことができる。</div>\EndKnitrBlock{rmdnote}



ラスタの再投影処理は、**terra** パッケージの `project()` を使用する。
前節で紹介した `st_transform()` 関数と同様、`project()` は空間オブジェクト (この場合はラスタデータセット) と何らかの CRS 表現を第 2 引数として受け取る。
第 2 引数には、異なる CRS を持つ既存のラスタオブジェクトを指定することもできる。

ラスタ変換の例として、カテゴリデータと連続データを使ったものを見てみよう。
土地被覆データは、通常、カテゴリ化された地図で表現される。
`nlcd.tif` ファイルは、以下のコードチャンクの出力に示すように、NAD83 / UTM ゾーン 12N CRS の [National Land Cover Database 2011](https://www.mrlc.gov/data/nlcd-2011-land-cover-conus) から取得した米国ユタ州の小領域の情報を提供する (出力の最初の行のみ示す)。


``` r
cat_raster = rast(system.file("raster/nlcd.tif", package = "spDataLarge"))
crs(cat_raster)
#> PROJCRS["NAD83 / UTM zone 12N",
#> ...
```

この地域では、8 つの土地被覆クラスが区別された (NLCD2011 の土地被覆クラスの全リストは、 [mrlc.gov](https://www.mrlc.gov/data/legends/national-land-cover-database-2011-nlcd2011-legend)で見ることができる)。


``` r
unique(cat_raster)
#>       levels
#> 1      Water
#> 2  Developed
#> 3     Barren
#> 4     Forest
#> 5  Shrubland
#> 6 Herbaceous
#> 7 Cultivated
#> 8   Wetlands
```

カテゴリ別ラスタを再投影する場合、推定値は元のラスタと同じでなければならない。
これは、各新規セルの値を入力ラスタの最も近いセル (中心) の値に設定する最近傍補間法 (`near`) を使って行うことができる。
例えば、ウェブマッピングに適した地理的 CRS である WGS84 に `cat_raster` を再投影している。
まず、この CRS の 定義を取得する。
次のステップは、`project()` 関数でラスタを再投影することである。カテゴリデータの場合は、最近傍補間法 (`near`) を使用する。


``` r
cat_raster_wgs84 = project(cat_raster, "EPSG:4326", method = "near")
```

新しいオブジェクトの多くのプロパティは、Table \@ref(tab:catraster) に示すように、列と行の数 (したがってセルの数)、解像度 (メートルから度に変換)、範囲など、以前のオブジェクトとは異なる (新しいカテゴリが作成されたのではなく、`NA` 値が追加されたため、カテゴリ数が 8 から 9 に増加していることに注意。土地被覆クラスは維持されている)。



Table: (\#tab:catraster)オリジナル (cat\_raster\_wgs84) と 投影 (cat\_raster\_wgs84) のカテゴリラスタ データセットの主要な属性。

|CRS   | nrow| ncol|   ncell| resolution| unique_categories|
|:-----|----:|----:|-------:|----------:|-----------------:|
|NAD83 | 1359| 1073| 1458207|    31.5275|                 8|
|WGS84 | 1246| 1244| 1550024|     0.0003|                 9|



数値ラスタ (`numeric` またはこの場合は `integer` の値) の再投影もほぼ同じ手順で行う。
これは、[Shuttle Radar Topography Mission (SRTM)](https://www2.jpl.nasa.gov/srtm/) の **spDataLarge** にある `srtm.tif` で実証されており、WGS84 CRS による海抜メートル (標高) の高さを表している。


``` r
con_raster = rast(system.file("raster/srtm.tif", package = "spDataLarge"))
cat(crs(con_raster))
#> GEOGCRS["WGS 84",
#>     DATUM["World Geodetic System 1984",
#>         ELLIPSOID["WGS 84",6378137,298.257223563,
#>             LENGTHUNIT["metre",1]]],
#>     PRIMEM["Greenwich",0,
#>         ANGLEUNIT["degree",0.0174532925199433]],
....
```

これから、このデータセットを投影型 CRS に再投影するが、カテゴリデータに適した最近傍法では<u>ない</u>。
その代わりに、元のラスタの 4 つの最近接セルに基づいて出力セルの値を計算する双一次補間法を使用する。^[
Section \@ref(resampling) に記載されている他の方法も、ここで使用することができる。
]
投影されたデータセットの値は、これら 4 つのセルの値の距離加重平均である。
入力セルが出力セルの中心に近いほど、その重みは大きくなる。
以下のコマンドは、WGS 84 / UTM zone 12N を表すテキストストリングを作成し、この CRS にラスタを双一次補間法 (`bilinear`) で再投影するものである (出力は示していない)。


``` r
con_raster_ea = project(con_raster, "EPSG:32612", method = "bilinear")
cat(crs(con_raster_ea))
```

数値変数のラスタ再投影は、セル数、解像度、範囲などの値や空間特性にも変化をもたらす。
これらの変化は、Table \@ref(tab:rastercrs) で実証されている。^[ 
もう一つの小さな変更点は、Table \@ref(tab:rastercrs) で表現されていないが、新しい投影ラスタデータセットの値のクラスが `numeric` になっていることである。
これは、双一次補間法 (`bilinear`) が連続データを扱うため、結果が整数値に型強制されることがほとんどないためである。
これは、ラスタデータセットを保存する際のファイルサイズに影響を与える可能性がある。
]



Table: (\#tab:rastercrs)オリジナル ('con\_raster') と投影 ('con\_raster\_ea') 連続ラスタデータセット の主要な属性。

|CRS          | nrow| ncol|  ncell| resolution| mean|
|:------------|----:|----:|------:|----------:|----:|
|WGS84        |  457|  465| 212505|     0.0008| 1843|
|UTM zone 12N |  515|  422| 217330|    83.5334| 1842|



\BeginKnitrBlock{rmdnote}<div class="rmdnote">もちろん、2 次元の地球投影の限界は、ラスタデータと同様にベクタデータにも当てはまる。
3 つの空間特性 (距離、面積、方向) のうち 2 つを維持することしかできない。
したがって、どの投影法を選択するかは、目の前の課題によって決まる。
例えば、密度 (1 グリッドセルあたりの点数や1グリッドセルあたりの住民数) に興味がある場合は、等面積投影を使用する (Chapter \@ref(location) も参照)。</div>\EndKnitrBlock{rmdnote}

## カスタム地図投影法  {#mapproj}

\index{CRS!カスタム} 
`EPSG:4326` のような `AUTHORITY:CODE` の識別子で捕捉される確立された CRS は、多くのアプリケーションに適している。
しかし、場合によっては、代替的な予測を使用したり、カスタム CRS を作成したりすることが望ましい。
Section \@ref(which-crs) は、カスタム CRS を使用する理由を述べ、いくつかの可能なアプローチを提示した。
ここでは、これらのアイデアを R で応用する方法を紹介する。

一つは、既存の CRS の WKT の定義を取り、その要素の一部を変更し、新しい定義を再投影に使用する方法である。
これは、空間ベクタでは `st_crs()` と `st_transform()` で、空間ラスタでは `crs()` と `project()` で行うことができる。次の例では、`zion` オブジェクトをカスタム正距方位図法 (AEQD) CRS に変換する例を示している。


``` r
zion = read_sf(system.file("vector/zion.gpkg", package = "spDataLarge"))
```

カスタム AEQD CRS を使用するには、データセットの中心点の座標を度数で知る必要がある (地理的 CRS)。
私たちの場合、`zion` 領域の重心を計算し、WGS84 に変換することでこの情報を抽出することができる。


``` r
zion_centr = st_centroid(zion)
zion_centr_wgs84 = st_transform(zion_centr, "EPSG:4326")
st_as_text(st_geometry(zion_centr_wgs84))
#> [1] "POINT (-113 37.3)"
```

次に、新たに得られた値を用いて、以下に示す正距方位図法 CRS の WKT 定義を更新することができる。
`"Central_Meridian"` は重心の経度、`"Latitude_Of_Origin"` は緯度であることに注意しておこう。


``` r
my_wkt = 'PROJCS["Custom_AEQD",
 GEOGCS["GCS_WGS_1984",
  DATUM["WGS_1984",
   SPHEROID["WGS_1984",6378137.0,298.257223563]],
  PRIMEM["Greenwich",0.0],
  UNIT["Degree",0.0174532925199433]],
 PROJECTION["Azimuthal_Equidistant"],
 PARAMETER["Central_Meridian",-113.0263],
 PARAMETER["Latitude_Of_Origin",37.29818],
 UNIT["Meter",1.0]]'
```

この方法の最後のステップは、元のオブジェクト (`zion`) を新しいカスタム CRS (`zion_aeqd`) に変換することである。


``` r
zion_aeqd = st_transform(zion, my_wkt)
```

カスタム投影法は、例えば [Projection Wizard](https://projectionwizard.org/#) のウェブアプリケーションを使って、対話的に行うことも可能である [@savric_projection_2016]。
このサイトでは、データの空間的範囲と歪みのプロパティを選択すると、可能な投影のリストが返される。
また、このリストには投影の WKT 定義が含まれており、コピーして再投影に使用することができる。
WKT 文字列を用いたカスタム CRS 定義の作成については、@opengeospatialconsortium_wellknown_2019 を参照。

\index{CRS!proj-string}
PROJ 文字列は、Section \@ref(crs-in-r) で述べた、投影、特に大きな地理的領域をカバーする幾何学に固有の制限を受け入れて、カスタム投影を作成するために使用することもできる。
多くの投影法が開発され、PROJ 文字列の `+proj=` の要素で設定することができる。 [PROJ website](https://proj.org/operations/projections/index.html) だけでも数十の投影法が詳細に記述されている。 

面積の関係を維持したまま世界を地図化する場合、Figure \@ref(fig:mollproj) に示されるモルワイデ図法 (Mollweide) が、一般的で賢明な選択となる [@jenny_guide_2017]。
この投影法を使用するには、`st_transform` 関数の proj-string 要素 `"+proj=moll"` を使って指定する必要がある。


``` r
world_mollweide = st_transform(world, crs = "+proj=moll")
```

<div class="figure" style="text-align: center">
<img src="figures/mollproj-1.png" alt="世界のモルワイデ図法。" width="100%" />
<p class="caption">(\#fig:mollproj)世界のモルワイデ図法。</p>
</div>

世界地図を作成する際、すべての空間特性 (面積、方向、距離) に対して歪みを最小化することが望まれることが多い。
これを実現するための代表的な投影法として、Figure \@ref(fig:wintriproj) に示される [ヴィンケル図法 (第 3 図法)](https://www.winkel.org/other/Winkel%20Tripel%20Projections.htm) (Winkel Tripel Projections) がある。^[
この投影図は、ナショナルジオグラフィック協会などで使用されている。
]
結果は、以下のコマンドで作成された。


``` r
world_wintri = st_transform(world, crs = "+proj=wintri")
```



<div class="figure" style="text-align: center">
<img src="figures/wintriproj-1.png" alt="世界のヴィンケル第 3 図法。" width="100%" />
<p class="caption">(\#fig:wintriproj)世界のヴィンケル第 3 図法。</p>
</div>





さらに、proj-string パラメータはほとんどの CRS 定義で変更可能であり、例えば `+lon_0` と `+lat_0` パラメータを使用して投影の中心を調整することができる。
以下のコードは、ニューヨークの経度と緯度を中心としたランベルト正積方位図法 (Lambert azimuthal equal-area projection) に座標を変換するものである (Figure \@ref(fig:laeaproj2))。


``` r
world_laea2 = st_transform(world,
                           crs = "+proj=laea +x_0=0 +y_0=0 +lon_0=-74 +lat_0=40")
```

<div class="figure" style="text-align: center">
<img src="figures/laeaproj2-1.png" alt="ニューヨークを中心とした世界のランベルト正積方位図法。" width="100%" />
<p class="caption">(\#fig:laeaproj2)ニューヨークを中心とした世界のランベルト正積方位図法。</p>
</div>

CRS の変更に関する詳しい情報は、[Using PROJ](https://proj.org/usage/index.html) のドキュメントに記載されている。

## 演習


E1. オブジェクト `nz` を WGS84 CRS に変換した `nz_wgs` というオブジェクトを作成しなさい。

- クラス `crs` のオブジェクトを作成し、CRS を調べなさい。
- オブジェクトの範囲への参照について、CRS によってどの単位を使っているか？
- `nz_wgs` から CRS を削除してプロットしなさい。New Zealand の地図のどこがおかしいか？その理由は？



E2. データセット `world` をユニバーサル横メルカトル図法に変換し (`"+proj=tmerc"`)、っ結果をプロットしなさい。
何が変わったか? その理由は?
WGS 84 に戻してプロットしなさい。
なぜ、このオブジェクトはオリジナルと異なるのか?



E3. 連続色ラスタ (`con_raster`) を、最近傍補間法で NAD83 / UTM zone 12N に変換しなさい。
何が変わったか?
それは、結果にどのように影響するか?



E4. 影鳥ラスタ (`cat_raster`) を、双一次補間法 (biulinear) で WGS 84 に変換しなさい。
何が変わったか?
それは、結果にどのように影響するか?



<!--toDo:jn-->
<!--improve/replace/modify the following q-->
<!-- E5. Create your own proj-string.  -->
<!-- It should have the Lambert Azimuthal Equal Area (`laea`) projection, the WGS84 ellipsoid, the longitude of projection center of 95 degrees west, the latitude of projection center of 60 degrees north, and its units should be in meters. -->
<!-- Next, subset Canada from the `world` object and transform it into the new projection.  -->
<!-- Plot and compare a map before and after the transformation. -->

<!-- ```{r 06-reproj-40} -->
<!-- new_p4s = "+proj=laea +ellps=WGS84 +lon_0=-95 +lat_0=60 +units=m" -->
<!-- canada = dplyr::filter(world, name_long == "Canada") -->
<!-- new_canada = st_transform(canada, new_p4s) -->
<!-- par(mfrow = c(1, 2)) -->
<!-- plot(st_geometry(canada), graticule = TRUE, axes = TRUE) -->
<!-- plot(st_geometry(new_canada), graticule = TRUE, axes = TRUE) -->
<!-- ``` -->

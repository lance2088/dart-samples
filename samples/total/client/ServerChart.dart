// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void ImageCallback(String dataUrl);

/**
 * A chart generated by the Google Chart API (see [http://code.google.com/apis/chart/image/]).
 */
class ServerChart extends Chart {
  String _params;
  Window _window;

  /**
   * Construct a [ServerChart] with a given parameter string containing any parameters
   * specific to a given chart type.
   */
  ServerChart(this._window, this._params) : super() {
  }

  void addParameter(String param) {
    _params += param;
  }

  // TODO:  error handling
  /**
   * Request a chart from the Google Chart API server.  The resulting chart will be
   * passed as a parameter to the [callback] function as a data URI suitable to be
   * added as the [:src:] attribute of an [:img:] element.
   */
  void render(ImageCallback callback) {
    // Use a random chart ID to avoid browser caching
    int random = (Math.random() * 1000000).toInt();
    String url = "http://chart.googleapis.com/chart?chid=${random}";

    XMLHttpRequest request = new XMLHttpRequest();
    request.on.readyStateChange.add((Event event) {
      if (request.readyState == XMLHttpRequest.DONE && request.status == 200) {
        callback("data:image/png;base64,${StringUtils.base64Encode(request.responseText)}");
      }
    });

    StringBuffer sb = new StringBuffer();
    // Chart type and unique params
    sb.add(_params);

    // Chart size
    sb.add("&chs=${width}x${height}");

    // Chart title
    if (title != null) {
      sb.add("&chtt=${title}"); // TODO: escaping
    }

    // Chart margins
    sb.add("&chma=5,50,5,5");

    // Labels
    sb.add("&chdl=");
    for (int col = _firstCol; col <= _lastCol; col++) {
      sb.add(_seriesLabels[col - _firstCol]);
      if (col < _lastCol) {
        sb.add("|");
      }
    }

    // Data values
    sb.add("&chd=t:");
    bool needPipe = false;
    for (int col = _firstCol; col <= _lastCol; col++) {
      List<double> values = getSeries(col);
      bool needComma = false;
      for (int i = 0; i < values.length; i++) {
        if (needPipe) {
          sb.add("|");
          needPipe = false;
        }
        if (needComma) {
          sb.add(",");
        }
        sb.add(values[i].toString());
        needComma = true;
      }
      needPipe = true;
    }
    String data = sb.toString();

    request.open("POST", url, true, null, null);
    request.setRequestHeader("Content-type", "text/plain");
    request.overrideMimeType("text/plain; charset=x-user-defined");
    print("Chart request: ${data}");
    request.send(data);
  }
}

class ServerXYChart extends ServerChart {
  ServerXYChart(Window window, String params) : super(window, params) {
    // Chart axes
    addParameter("&chxt=x,y");
    // Chart colors
    addParameter("&chco=ff0000,00ff00,0000ff,ffff00,ff00ff,00ffff,000000");
  }

  void setData(CellRange range) {
    super.setData(range);

    // Axis ranges
    addParameter("&chxr=0,${_firstRow},${_lastRow}|1,${_minValue},${_maxValue}");

    // Data range
    addParameter("&chds=${_minValue},${_maxValue}");
  }
}

class ServerLineChart extends ServerXYChart {
  ServerLineChart(Window window) : super(window, "cht=lc") {
    // Chart colors
    addParameter("&chco=ff0000,00ff00,0000ff,ffff00,ff00ff,00ffff,000000");
  }
}

// TODO:  horizontal charts require switched axes
//class ServerHorizontalGroupedBarChart extends ServerChart {
//  ServerHorizontalGroupedBarChart(Window window, CellRange range)
//      : super(window, range, "cht=bhg") { }
//}
//
//class ServerHorizontalStackedBarChart extends ServerChart {
//  ServerHorizontalStackedBarChart(Window window, CellRange range)
//      : super(window, range, "cht=bhs") { }
//}
//
//class ServerHorizontalOverlappedBarChart extends ServerChart {
//  ServerHorizontalOverlappedBarChart(Window window, CellRange range)
//      : super(window, range, "cht=bho") { }
//}

class ServerPieChart extends ServerChart {
  ServerPieChart(Window window, String param) : super(window, param) { }

  void setData(CellRange range) {
    super.setData(range);

    StringBuffer labels = new StringBuffer();
    labels.add("&chl=");

    for (int col = _range.minCorner.col; col <= _range.maxCorner.col; col++) {
      List<double> data = getSeries(col);
      for (int i = 0; i < data.length; i++) {
        double value = data[i];
        String v = StringUtils.twoDecimals(value);
        if (i > 0) {
          labels.add("|");
        }
        labels.add(v);
      }
      if (col < _range.maxCorner.col) {
        labels.add("|");
      }
    }
    addParameter(labels.toString());
  }
}

class Server2DPieChart extends ServerPieChart {
  Server2DPieChart(Window window) : super(window, "cht=p") { }
}

class Server3DPieChart extends ServerPieChart {
  Server3DPieChart(Window window) : super(window, "cht=p3") {
    height = (width / 2.5).toInt();
  }
}

class ServerConcentricPieChart extends ServerPieChart {
  ServerConcentricPieChart(Window window) : super(window, "cht=pc") { }
}

class ServerVerticalGroupedBarChart extends ServerXYChart {
  ServerVerticalGroupedBarChart(Window window) : super(window, "cht=bvg&chbh=a") { }
}

class ServerVerticalStackedBarChart extends ServerXYChart {
  ServerVerticalStackedBarChart(Window window) : super(window, "cht=bvs&chbh=a") { }
}

class ServerVerticalOverlappedBarChart extends ServerXYChart {
  ServerVerticalOverlappedBarChart(Window window) : super(window, "cht=bvo&chbh=a") { }
}
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

module MyBarrel{
    (:graph)
    module Graph{
	class Trend extends WatchUi.Drawable{
		var xAxis as Axis;
		var yAxis as Axis;
		var series as Array<Serie> = [] as Array<Serie>;
		var markers as Array<Marker> = [] as Array<Marker>;

		public var frameColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var textColor as Graphics.ColorType = Graphics.COLOR_BLACK;

		hidden var axisPenWidth as Number = 3;
		hidden var markerFont as FontType = Graphics.FONT_XTINY;
		hidden var markerSize as Number = 6;

		function initialize(options as {
			:xAxis as Axis, // required
			:yAxis as Axis, // required
			:locX as Number, 
			:locY as Number,
			:width as Number, 
			:height as Number,
			:series as Array<Serie>,
			:darkMode as Boolean,
			:xRangeMin as Float,
		}){
			var requiredOptions = [:xAxis, :yAxis] as Array<Symbol>;
			for(var i=0; i<requiredOptions.size(); i++){
				var key = requiredOptions[i];
				if(!options.hasKey(key)){
					throw new Lang.InvalidOptionsException(Lang.format("Missing option: $1$", [key.toString()]));
				}
			}
			xAxis = options.get(:xAxis) as Axis;
			yAxis = options.get(:yAxis) as Axis;

			if(!options.hasKey(:identifier)){ options.put(:identifier, "Graph"); }
			Drawable.initialize(options);
			if(options.hasKey(:series)){ setSeries(options.get(:series) as Array<Serie>); }
			if(options.hasKey(:darkMode)){ setDarkMode(options.get(:darkMode) as Boolean); }

			updateSeriesArea();
		}

		function draw(dc as Dc) as Void{
			drawFrame(dc);

			for(var i=0; i<series.size(); i++){
				series[i].draw(dc);
			}

			for(var i=0; i<markers.size(); i++){
				markers[i].draw(dc);
			}
		}

		protected function drawFrame(dc as Dc) as Void{
			var axisOffset = 0.5f * axisPenWidth; // space for the axis width

			var x1 = locX + axisOffset;
			var x2 = locX + width - axisOffset;
			var y1 = locY + axisOffset;
			var y2 = locY + height - axisOffset;

			// draw the xy-axis frame
			dc.setPenWidth(axisPenWidth);
			dc.setColor(frameColor, Graphics.COLOR_TRANSPARENT);
			dc.drawLine(x1, y1, x1, y2);
			dc.drawLine(x1, y2, x2, y2);
			dc.drawLine(x2, y2, x2, y1);
		}

		function setSeries(series as Array<Serie>) as Void{
			for(var i=0; i<series.size(); i++){
				var serie = series[i];
				serie.xAxis = xAxis;
				serie.yAxis = yAxis;
			}
			self.series = series;
		}

		public function setDarkMode(darkMode as Boolean) as Void{
			self.textColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
			self.frameColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
		}

		function setSize(w as Numeric, h as Numeric) as Void{
			Drawable.setSize(w, h);
			updateSeriesArea();
		}

		function setLocation(x as Numeric, y as Numeric) as Void{
			Drawable.setLocation(x, y);
			updateSeriesArea();
		}

		hidden function setAxisPenWidth(penWidth as Number) as Void{
			self.axisPenWidth = penWidth;
			updateSeriesArea();
		}

		function updateSeriesArea() as Void{
			var x = locX + axisPenWidth;
			var y = locY + axisPenWidth;
			var w = width - (2 * axisPenWidth);
			var h = height - (2 * axisPenWidth);

			for(var i=0; i<series.size(); i++){
				series[i].setLocation(x, y);
				series[i].setSize(w, h);
			}
		}
	}
}
}
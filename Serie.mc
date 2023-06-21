import Toybox.Lang;
import Toybox.Graphics;

module MyGraph{

	enum DrawStyle {
		DRAW_STYLE_FILLED = 0x0,
		DRAW_STYLE_LINE = 0x1,
	}
	enum MarkerType{
		MARKER_MIN = 0x1,
		MARKER_MAX = 0x2,
	}

	class Serie{

		var color as Graphics.ColorType or Null = null; // if null then let the graph decide (based upon background)
		var data as ISerieData;
		var style as DrawStyle = DRAW_STYLE_FILLED;
		var markers as MarkerType or Number = MARKER_MIN | MARKER_MAX;
		var yRangeMin as Numeric = 20.0f; // (x,y) minimum range

		function initialize(options as {
			:data as ISerieData,  // required
			:color as ColorType, // optional
			:style as DrawStyle, //optional
			:markers as MarkerType,
			:yRangeMin as Numeric,
		}){
			data = options.hasKey(:data)
				? options.get(:data) as ISerieData
				: new FilteredData({});
			if(options.hasKey(:color)){ color = options.get(:color); }
			if(options.hasKey(:style)){ style = options.get(:style) as DrawStyle; }
			if(options.hasKey(:markers)){ markers = options.get(:markers) as Number; }
			if(options.hasKey(:yRangeMin)){ yRangeMin = options.get(:yRangeMin) as Numeric; }
		}
	}
}
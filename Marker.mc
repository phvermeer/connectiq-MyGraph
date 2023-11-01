import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

module MyGraph{
    class Marker extends WatchUi.Drawable{
        var serie as Serie;
        var color as ColorType;
        var size as Numeric;
        var textColor as ColorType;
        var font as FontType;
        var text as String?;
        var pt as DataPoint?;

		function initialize(options as {
            :size as Numeric,
			:color as ColorType,
			:textColor as ColorType,
			:font as FontType,
            :text as String,
            :serie as Serie?,
        }){
            Drawable.initialize(options);
            if(!options.hasKey(:serie)){
                throw new InvalidOptionsException("Missing option :serie");
            }
            serie = options.get(:serie) as Serie;
            color = options.hasKey(:color) ? options.get(:color) as ColorType : Graphics.COLOR_GREEN;
            textColor = options.hasKey(:textColor) ? options.get(:textColor) as ColorType : Graphics.COLOR_DK_GRAY;
            font = options.hasKey(:font) ? options.get(:font) as FontType : Graphics.FONT_XTINY;
            size = options.hasKey(:size) ? options.get(:size) as Numeric : 6;
            if(options.hasKey(:text)){ text = options.get(:text) as String; }
        }

        function draw(dc as Dc) as Void{
            if(serie != null){
                var xAxis = serie.xAxis;
                var yAxis = serie.yAxis;
                if(xAxis != null && yAxis != null && pt != null && pt.y != null){
                    var pt = self.pt as DataPoint;
                    var pt_y = pt.y as Numeric;

                    // Prepare drawing
                    var xFactor = xAxis.getFactor(serie.width);
                    var yFactor = yAxis.getFactor(serie.height);
                    var x = serie.locX + xFactor * (pt.x - xAxis.min);
                    var y = serie.locY + yFactor * (yAxis.max - pt_y);

                    //    X-------X
                    //     \     /   height = size
                    //      \   /    width = size * sqrt(2)
                    //        X
                    var w2 = 0.7 * size;
                    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                    dc.fillPolygon([
                        [x, y] as Array<Numeric>,
                        [x-w2, y-size] as Array<Numeric>,
                        [x+w2, y-size] as Array<Numeric>
                    ] as Array< Array<Numeric> >);

                    // Draw the text
                    if(text != null){
                        var w_h = dc.getTextDimensions(text, font);
                        var marginLeft = Graphics.getFontDescent(font)/2;
                        w2 = w_h[0]/2;
                        var h = w_h[1];

                        var xText = x;
                        if((x-w2) < (serie.locX + marginLeft)){
                            xText = serie.locX + marginLeft + w2;
                        }else if((x+w2) > (serie.locX + serie.width - marginLeft)){
                            xText = serie.locX + serie.width - marginLeft - w2;
                        }

                        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
                        dc.drawText(xText, y-size-h, font, text as String, Graphics.TEXT_JUSTIFY_CENTER);
                    }
                }
            }
        }

        function getHeight() as Numeric{
            // get height to reserve space above the graph
            var h = size; // triangle shape
            if(text != null){
                h += Graphics.getFontHeight(font);
            }
            return h;
        }
    }
}
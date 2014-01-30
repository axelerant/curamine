
require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/stacked_mixin'

class AdvancedRoadmap::Gruff::StackedBar < AdvancedRoadmap::Gruff::Base
    include StackedMixin

    # Draws a bar graph, but multiple sets are stacked on top of each other.
    def draw
      get_maximum_by_stack
      super
      return unless @has_data

      # Setup spacing.
      #
      # Columns sit stacked.
      @bar_spacing ||= 0.9
      @bar_width = @graph_width / @column_count.to_f
      padding = (@bar_width * (1 - @bar_spacing)) / 2
    
      @d = @d.stroke_opacity 0.0
      
      height = Array.new(@column_count, 0)
    
      @norm_data.each_with_index do |data_row, row_index|      
        data_row[DATA_VALUES_INDEX].each_with_index do |data_point, point_index|
          @d = @d.fill data_row[DATA_COLOR_INDEX]
          
          # Calculate center based on bar_width and current row
          label_center = @graph_left + (@bar_width * point_index) + (@bar_width * @bar_spacing / 2.0)
          draw_label(label_center, point_index)

          next if (data_point == 0)
          # Use incremented x and scaled y
          left_x = @graph_left + (@bar_width * point_index) + padding
          left_y = @graph_top + (@graph_height -
                                 data_point * @graph_height - 
                                 height[point_index]) + 1
          right_x = left_x + @bar_width * @bar_spacing
          right_y = @graph_top + @graph_height - height[point_index] - 1
          
          # update the total height of the current stacked bar
          height[point_index] += (data_point * @graph_height ) 
          
          @d = @d.rectangle(left_x, left_y, right_x, right_y)
          
        end

      end
    
      @d.draw(@base_image)    
    end

end

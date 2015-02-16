# This file is a part of Redmin Agile (redmine_agile) plugin,
# Agile board plugin for redmine
#
# Copyright (C) 2011-2015 RedmineCRM
# http://www.redminecrm.com/
#
# redmine_agile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_agile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_agile.  If not, see <http://www.gnu.org/licenses/>.

module RedmineAgile
  module HeaderTree
    class HeaderTree
      class HeaderTreeNode
        attr_accessor :leaf

        def initialize(name = nil, level = 0)
          @name = name
          @level = level
          @children = ActiveSupport::OrderedHash.new
        end

        def has_child?(name, has_leaf)
          @children.keys.last == [name, has_leaf, @children.keys.size - 1]
        end

        def get_child(name, has_leaf)
          k = @children.keys.select{ |x| x.first(2) == [name, has_leaf] }.last
          @children[k]
        end

        def add_child(name, has_leaf)
          @children[[name, has_leaf, @children.keys.size]] = HeaderTreeNode.new(name, @level + 1)
        end

        def branch_width
          if @leaf
            1
          else
            @children.values.map(&:branch_width).sum
          end
        end

        def depth
          if @leaf
            1
          else
            1 + @children.values.map(&:depth).max
          end
        end

        def render(levels)
          height = if @children.values.any? then 1 else levels.size - @level end
          levels[@level] ||= []
          levels[@level] << [@name, height, branch_width, @leaf]
          @children.values.each do |child|
            child.render(levels)
          end
          levels
        end

        def to_s
          "#{"\t" * @level}#{@name || 'ROOT'} depth: #{depth}, width: #{branch_width}, level: #{@level}, leaf: #{!!@leaf}\n" + 
            @children.values.map(&:to_s).join
        end
      end

      def initialize
        @root = HeaderTreeNode.new
      end

      def put(path, leaf, node = nil)
        node_to_put = node || @root
        child_node_name = path.first
        path_left = path[1..-1]
        has_leaf = path_left.empty?
        if node_to_put.has_child? child_node_name, has_leaf
          child = node_to_put.get_child(child_node_name, has_leaf)
        else
          child = node_to_put.add_child(child_node_name, has_leaf)
        end
        if has_leaf
          child.leaf = leaf
        else
          put path_left, leaf, child
        end
      end

      def depth
        @root.depth - 1 # Because root itself is not treat as node
      end

      def render
        maxdepth = depth
        levels = Array.new maxdepth + 1
        @root.render(levels)
      end

      def to_s
        @root.to_s
      end
    end
  end
end  

unless AgileBoardsHelper.included_modules.include?(RedmineAgile::HeaderTree)
  AgileBoardsHelper.send(:include, RedmineAgile::HeaderTree)
end

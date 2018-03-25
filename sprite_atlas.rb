#!/usr/bin/ruby

require 'chunky_png'
require 'json'
require 'set'

class Vec2
	attr_accessor :x
	attr_accessor :y

	def initialize(x,y)
		@x=x
		@y=y
	end

	def to_s
		return "(#{x},#{y})"
	end

	def ==(o)
		return (o.class == Vec2 and o.x == @x and o.y == @y)
	end

	def eql?(o)
		return o == self
	end

	def hash()
		return (@x << 16) + @y
	end
end

class Rect
	attr_accessor :x
	attr_accessor :y
	attr_accessor :w
	attr_accessor :h

	def initialize(x, y, w, h)
		@x = x
		@y = y
		@w = w
		@h = h
	end

	def left()
		return @x
	end

	def right()
		return @x + @w
	end

	def top()
		return @y
	end

	def bottom()
		return @y + @h
	end

	def intersects(o)
		a = self
		b = o
		a1 = (a.left < b.right)
		a2 = a.right > b.left
		a3 = a.top < b.bottom
		a4 = a.bottom > b.top
		return (a1 && a2 && a3 && a4) 
	end

	def ==(o)
		return (o.x == @x and o.y == @y and o.w == @w and o.h == @h)
	end

	def eql?(o)
		return o == self
	end

	def hash()
		return ((@x & 0xff) << 24) + ((@y & 0xff) << 16) + ((@w & 0xff) << 8) + (@h & 0xff)
	end
end

def max (a,b)
  a>b ? a : b
end

def generate_atlas(sprite_list, out_png_filename, out_json_filename, expand, power_of_two)
	# Insert largest images first, this usually makes the atlas smaller
	insertion_order = sprite_list.keys
	insertion_order.sort! { |img_a,img_b|
		size_a = sprite_list[img_a][:size]
		size_b = sprite_list[img_b][:size]
		size_b <=> size_a
	}

	insertion_position_candidates = [Vec2.new(0,0)].to_set
	rectangles = []
	rect_to_sprite_mapping = {}

	puts "Finding position for each sprite..."
	counter = 0
	insertion_order.each { |filename|
		w = sprite_list[filename][:w]
		h = sprite_list[filename][:h]

		insert_to = nil
		best_metric = -1
		insertion_position_candidates.each { |pos_cand|
			rect_cand = Rect.new(pos_cand.x,pos_cand.y,w,h)

			failed = false
			rectangles.each { |r|
				if r.intersects(rect_cand) then
					failed = true
					break
				end
			}
			if failed then
				next
			end

			metric = max(pos_cand.x,pos_cand.y)
			if metric < best_metric or best_metric < 0 then
				best_metric = metric
				insert_to = pos_cand
			end
		}

		new_rect = Rect.new(insert_to.x,insert_to.y,w,h)
		rectangles.push(new_rect)
		insertion_position_candidates.delete(insert_to)
		rect_to_sprite_mapping[new_rect] = filename

		insertion_position_candidates.add(Vec2.new(new_rect.right,new_rect.top))
		insertion_position_candidates.add(Vec2.new(new_rect.left,new_rect.bottom))
		insertion_position_candidates.add(Vec2.new(new_rect.right,new_rect.bottom))
	}

	# Get size for the final atlas
	atlas_width = 0
	atlas_height = 0
	rectangles.each { |r|
		atlas_width = max(atlas_width,r.right)
		atlas_height = max(atlas_height,r.bottom)
	}
	if power_of_two then
		m = max(atlas_width,atlas_height)
		pot = 1
		while m > pot do
			pot = pot * 2
		end
		atlas_width = pot
		atlas_height = pot
	end

	# And finally copy image data to their respective positions in the atlas and create metadata JSON
	json = {}
	png = ChunkyPNG::Image.new(atlas_width, atlas_height, ChunkyPNG::Color::TRANSPARENT)
	rectangles.each { |r|
		fn = rect_to_sprite_mapping[r]
		puts "Adding " + fn
		png_data = sprite_list[fn][:data]
		png.replace!(png_data,r.x,r.y)

		n = File.basename(fn, '.*')
		json[n] = {}
		json[n]["frame"] = {
			"x" =>  r.x + expand,
			"y" =>  r.y + expand,
			"width" =>  r.w - 2*expand,
			"height" =>  r.h - 2*expand
		}
	}
	png.save(out_png_filename, :interlace => false)

	json_str = JSON.pretty_generate(json)
	File.open(out_json_filename, 'w') { |file| file.write(json_str) }
end

def parse_args()
	args = {}

	supported_args = {
		"in_dir" => {
			:params => 1,
			:required => true
		},
		"out_dir" => {
			:params => 1,
			:required => true
		},
		"atlas_name" => {
			:params => 1,
			:required => true
		},
		"expand" => {
			:params => 1,
			:required => false
		},
		"power_of_two" => {
			:params => 0,
			:required => false
		}
	}

	processed_indices = []

	ARGV.each_with_index { |arg, index|
		if processed_indices.include? index then
			next
		end

		re = /--([a-z_]*$)/
		m = arg.match(re)
		if not m then
			return nil
		end

		arg = m[1]
		if not supported_args.has_key? arg then
			return nil
		end

		expected_param_count = supported_args[arg][:params]

		if ARGV.count <= index + expected_param_count then
			return nil
		end

		processed_indices.push(index)
		expected_param_count.times { |t|
			processed_indices.push(index + 1 + t)
		}

		args[arg] = expected_param_count == 1 ? ARGV[index+1] : ARGV[(index+1)...(index+1+expected_param_count)]
	}

	supported_args.each { |argname, arg_params|
		if not args.has_key? argname and arg_params[:required] then
			puts "Required parameter " + argname + " is missing."
			puts ""
			return nil
		end
	}

	return args
end

def print_help()
	help_str = <<-FOO

sprite_atlas.rb by Antti Kuukka

A tool for creating sprite atlases from multiple png files.

SYNOPSIS:
    ruby sprite_atlas.rb --in_dir source_directory --out_dir target_directory
       --atlas_name atlasname [--expand N] [--power_of_two]

DESCRIPTION:

    The following options are available:

    --in_dir       Directory containing the png images that are put into the
                   sprite atlas. All files .png files in the directory are
                   automatically added.

    --out_dir      Where to put the output files (the actual sprite atlas .png
                   file and JSON metadata file).

    --atlas_name   Name for the output files. If your atlas_name is my_atlas,
                   the output files are my_atlas.png and my_atlas.json.

    --expand       (Optional) Number of empty pixels to put around each sprite
                   in the atlas. If unspecified, the default value is 0.

    --power_of_two (Optional) Forces the resulting sprite atlas to be
                   rectangular and width/height to be power of two.

FOO

	puts(help_str)
end

if __FILE__ == $0
	args = parse_args()
	if args == nil then
		print_help()
		exit()
	end

	src_dir = args["in_dir"]
	out_dir = args["out_dir"]
	atlas_name = args["atlas_name"]
	expand = 0
	if args.has_key? "expand" then
		expand = args["expand"].to_i
	end

	json_out_file = out_dir + "/" + atlas_name + ".json"
	png_out_file = out_dir + "/" + atlas_name + ".png"

	src_files = Dir[src_dir + "/*.png"]

	sprite_list = {}
	puts "Processing " + src_files.count().to_s + " images..."
	src_files.each do |f|
		sprite_list[f] = {}
		data = nil
		if expand == 0 then
			data = ChunkyPNG::Image.from_file(f)
		else
			imgdata = ChunkyPNG::Image.from_file(f)
			data = ChunkyPNG::Image.new(imgdata.width + 2*expand, imgdata.height + 2*expand, ChunkyPNG::Color::TRANSPARENT)
			data.replace!(imgdata,expand,expand)
		end
		sprite_list[f][:data] = data
		sprite_list[f][:w] = data.width
		sprite_list[f][:h] = data.height
		sprite_list[f][:size] = data.height*data.width
	end

	power_of_two = args.has_key? "power_of_two"

	generate_atlas(sprite_list, png_out_file, json_out_file, expand, power_of_two)
end
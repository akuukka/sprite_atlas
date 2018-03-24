#!/usr/bin/ruby

require 'chunky_png'
require 'json'

$files = {}

class Rect
	attr_accessor :imageFileName
	attr_accessor :w
	attr_accessor :h
	attr_accessor :children

	def initialize(x, y, w, h)
		@x = x
		@y = y
		@w = w
		@h = h
		@children = nil
		@imageFileName = nil
	end

	def to_s
		s = "R: (#{@x}x#{@y} , #{@w}x#{@h}) img: #{@imageFileName}\n"
		return s
	end

	def add(imageFileName, w, h)
		if @imageFileName != nil then
			return false
		end

		# Maybe some of the children can accommodate this?
		if @children != nil then
			@children.each do |child|
				success = child.add(imageFileName,w,h)
				if success then
					return true
				end
			end
		else
			if w > @w or h > @h then
				return false
			end
			if w == @w and h == @h then
				@imageFileName = imageFileName
				return true
			end

			if w < @w and h == @h then
				r0 = Rect.new(@x,@y,w,h)
				r0.imageFileName = imageFileName
				r1 = Rect.new(@x + w,@y,@w-w,h)
				@children = [r0,r1]
				return true
			end

			if w == @w and h < @h then
				r0 = Rect.new(@x,@y,w,h)
				r0.imageFileName = imageFileName
				r1 = Rect.new(@x,@y+h,@w,@h-h)
				@children = [r0,r1]
				return true
			end

			if w < @w and h < @h then
				r0 = Rect.new(@x,@y,w,h)
				r0.imageFileName = imageFileName
				r1 = Rect.new(@x,@y+h,w,@h-h)
				r2 = Rect.new(@x+w,@y,@w-w,h)
				r3 = Rect.new(@x + w,@y + h,@w-w,@h-h)
				@children = [r0,r1,r2,r3]
				return true
			end

		end

		return false
	end

	def increase_size(n)
		nw = @w + n
		nh = @h + n

		r0 = Rect.new(@x,@y,@w,@h)
		if @imageFileName != nil then
			r0.imageFileName = @imageFileName
			@imageFileName = nil
		else
			r0.children = @children
		end

		r1 = Rect.new(@x,@y + @h,@w,n)
		r2 = Rect.new(@x + @w,@y,n,@h)
		r3 = Rect.new(@x + @w,@y + @h,n,n)
		@children = [r0,r1,r2,r3]

		@w = nw
		@h = nh
	end

	def write_to_png(png)
		if imageFileName != nil then
			puts "Writing " + @imageFileName
			$files[@imageFileName]["out_x"] = @x
			$files[@imageFileName]["out_y"] = @y

			if $files.has_key? @imageFileName then
				data = $files[@imageFileName]["data"]
				png.replace!(data,@x,@y)
			end
		end
		if @children != nil then
			@children.each do |child|
				child.write_to_png(png)
			end
		end
	end

end

$root = nil

def add(root, imageFileName, w, h, allowResize = true)
	if $root == nil then
		$root = Rect.new(0,0,w,h)
	end

	success = $root.add(imageFileName,w,h)
	if not success then
		if not allowResize then
			return
		end
		$root.increase_size(w > h ? w : h)
		success = $root.add(imageFileName,w,h)
	end
end

def create_png(root, filename)
	png = ChunkyPNG::Image.new(root.w, root.h, ChunkyPNG::Color::TRANSPARENT)
	root.write_to_png(png)
	png.save(filename, :interlace => true)
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
    ruby sprite_atlas.rb --in_dir source_directory --out_dir target_directory --atlas_name atlasname [--expand N]

DESCRIPTION:

    The following options are available:

    --in_dir       Directory containing the png images that are put into the sprite atlas. All files .png files
                   in the directory are automatically added.

    --out_dir      Where to put the output files (the actual sprite atlas .png file and JSON metadata file).

    --atlas_name   Name for the output files. If your atlas_name is my_atlas, the output files are my_atlas.png
                   and my_atlas.json.

    --expand       Number of empty pixels to put around each sprite in the atlas. If unspecified, the default
                   value is 0.

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

	puts "Processing " + src_files.count().to_s + " images..."
	src_files.each do |f|
		$files[f] = {}
		data = nil
		if expand == 0 then
			data = ChunkyPNG::Image.from_file(f)
		else
			imgdata = ChunkyPNG::Image.from_file(f)
			data = ChunkyPNG::Image.new(imgdata.width + 2*expand, imgdata.height + 2*expand, ChunkyPNG::Color::TRANSPARENT)
			data.replace!(imgdata,expand,expand)
		end
		$files[f]["data"] = data
		$files[f][:w] = data.width
		$files[f][:h] = data.height
		$files[f][:size] = data.height*data.width
	end

	# A very simple optimization: sort the source file list so that largest images come first. This usually makes the atlas smaller.
	src_files.sort! { |img_a,img_b|
		size_a = $files[img_a][:size]
		size_b = $files[img_b][:size]
		size_b <=> size_a
	}

	src_files.each do |f|
		add($root, f, $files[f][:w],$files[f][:h])
	end
	create_png($root, png_out_file)

	json = {}
	src_files.each do |f|
		n = File.basename(f, '.*')
		json[n] = {}
		json[n]["frame"] = {
			"x" =>  $files[f]["out_x"] + expand,
			"y" =>  $files[f]["out_y"] + expand,
			"width" =>  $files[f][:w] - 2*expand,
			"height" =>  $files[f][:h] - 2*expand
		}
	end

	json_str = JSON.pretty_generate(json)

	File.open(json_out_file, 'w') { |file| file.write(json_str) }
end
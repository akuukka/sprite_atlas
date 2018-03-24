#!/usr/bin/ruby

require 'chunky_png'
require 'json'

$files = {}
$png_out_file = nil

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
		g = Random.rand(255)
		if imageFileName != nil then
			puts "Writing " + @imageFileName
			$files[@imageFileName]["out_x"] = @x
			$files[@imageFileName]["out_y"] = @y

			if $files.has_key? @imageFileName then
				data = $files[@imageFileName]["data"]
				png.replace!(data,@x,@y)
			else
				@h.times do |y|
					@w.times do |x|
						png[@x + x, @y + y] = ChunkyPNG::Color.rgba(0, g, 0, 255)	
					end
				end
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

src_dir = ARGV[0]
out_dir = ARGV[1]
atlas_name = ARGV[2]

if out_dir == nil or atlas_name == nil or src_dir == nil then
	abort("Usage: ruby sprite_atlas.rb srcdir outdir atlasname")
end

json_out_file = out_dir + "/" + atlas_name + ".json"
$png_out_file = out_dir + "/" + atlas_name + ".png"

# Read config
expand = 0
json_file = src_dir + "/" + "atlas.json"
if File.exists? json_file then
	atlas_config = JSON.parse(File.read(json_file))
	expand = atlas_config["Expand"].to_i
end

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
	$files[f]["w"] = data.width
	$files[f]["h"] = data.height
	$files[f]["s"] = data.height*data.width
end

# A very simple optimization: sort the source file list so that largest images come first. This usually makes the atlas smaller.
src_files.sort! { |img_a,img_b|
	size_a = $files[img_a]["s"]
	size_b = $files[img_b]["s"]
	size_b <=> size_a
}

src_files.each do |f|
	add($root, f, $files[f]["w"],$files[f]["h"])
end
create_png($root, $png_out_file)

json = {}
src_files.each do |f|
	n = File.join(File.dirname(f), File.basename(f, '.*'))
	json[n] = {}
	json[n]["frame"] = {
		"x" =>  $files[f]["out_x"] + expand,
		"y" =>  $files[f]["out_y"] + expand,
		"width" =>  $files[f]["w"] - 2*expand,
		"height" =>  $files[f]["h"] - 2*expand
	}
end

json_str = JSON.pretty_generate(json)

File.open(json_out_file, 'w') { |file| file.write(json_str) }
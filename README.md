# sprite_atlas
A simple Ruby script that creates sprite atlases. Supports PNG only.

This is not trying to be the most powerful sprite atlas tool in the world. It's not really fast, nor is the packing algorithm highly optimized. But it's good enough for many purposes and it's free and can be easily integrated to your build processes.

Usage:

First, please install a Ruby gem called chunky-png:

> gem install chunky_png

To create a sprite atlas:

> ruby sprite_atlas.rb --in_dir source_directory --out_dir target_directory --atlas_name atlasname [--expand N]

Description of the parameters:

in_dir: Directory containing the png images that are put into the sprite atlas. All files .png files in the directory are automatically added.

out_dir: Where to put the output files (the actual sprite atlas .png file and JSON metadata file).

atlas_name: Name for the output files. If your atlas_name is my_atlas, the output files are my_atlas.png and my_atlas.json.

expand: (Optional) Number of empty pixels to put around each sprite in the atlas. If unspecified, the default value is 0.


sprite_atlas is licensed under the MIT license.

Copyright 2018 Antti Kuukka

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# sprite_atlas
A simple Ruby script that creates sprite atlases. Supports PNG only.

This is not trying to be the most powerful sprite atlas tool in the world. It's not really fast, nor is the packing algorithm highly optimized. But it's good enough for many purposes and it's free and can be easily integrated to your build processes.

Usage:

First, please install a Ruby gem called chunky-png:

> gem install chunky_png

To create a sprite atlas:

> ruby sprite_atlas.rb in_dir out_dir atlas_name

in_dir is the directory which contains the PNG files you want to create the atlas from. out_dir refers to the output directory, which will contain two files: atlas_name.png which is the sprite atlas as png image, and atlas_name.json which contains the metadata you need to use the sprite atlas. All .png files inside in_dir will be included in the atlas. The directory in_dir may also contain an optional configuration file, named atlas.json, which is of following format:

>{
>  "Expand": n
>}

The supported configuration options are:

Expand: how many empty pixels to put around each sprite in the atlas (to prevent artifacts from neighbouring sprites from appearing due to interpolation). The default value, which is used when no configuration file is present, is 0.


sprite_atlas is licensed under the MIT license.

Copyright 2018 Antti Kuukka

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
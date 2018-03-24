# sprite_atlas
A simple Ruby script that creates sprite atlases. Supports PNG only.

This is not trying to be the most powerful sprite atlas tool in the world. It's not really fast, nor is the packing algorithm highly optimized. But it's good enough for many purposes and it's free and can be easily integrated to your build processes.

Usage:

> ruby sprite_atlas.rb in_dir out_dir atlas_name

in_dir is the directory which contains the PNG files you want to create the atlas from. out_dir refers to the output directory, which will contain two files: atlas_name.png which is the sprite atlas as png image, and atlas_name.json which contains the metadata you need to use the sprite atlas. All .png files inside in_dir will be included in the atlas. The directory in_dir may also contain an optional configuration file, named atlas.json, which is of following format:

>{
>  "Expand": n
>}

The supported configuration options are:

Expand: how many empty pixels to put around each sprite in the atlas (to prevent artifacts from neighbouring sprites from appearing due to interpolation). The default value, which is used when no configuration file is present, is 0.
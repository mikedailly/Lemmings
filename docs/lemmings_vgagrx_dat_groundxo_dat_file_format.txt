How to Read vgagrX.dat files and groundXo.dat files
---------------------------------------------------

document by ccexplore

clarification on 4-bit bitmaps by Simon


This document assumes that you know about the general .DAT decompression
algorithm.  The vgagrX.dat files are compressed with that, so the first step
you'd want to take is to decompress it.  You will end up with 2 sections of
decompressed data.  The groundXo.dat files are not compressed.


groundXo.dat
------------

This file is vital to intepreting vgagrX.dat, since groundXo.dat describes the
characteristics of the bitmaps contained in vgagrX.dat.  You will note that
all groundXo.dat have the same size.  They all follow this organization:

OBJECT_INFO[16]
TERRAIN_INFO[64]
PALETTES

In other words, first comes 16 slots for describing 16 objects.  The object
IDs in the .LVL file is really referring to this array.  Then comes 64 slots
for describing 64 terrain pieces.  Again, the terrain IDs in the .LVL file is
really referring to this array.  Finally comes a bunch of palettes.

I'll now describe each chunk in detail:


OBJECT_INFO
-----------

An OBJECT_INFO slot is 28 bytes in size, so the OBJECT_INFO array takes up a
total of 28*16 = 448 bytes.  The structure of a single OBJECT_INFO is as
follows:

WORD animation_flags;
BYTE start_animation_frame_index;
BYTE end_animation_frame_index;
BYTE width;
BYTE height;
WORD animation_frame_data_size;
WORD mask_offset_from_image;
WORD unknown1;
WORD unknown2;
WORD trigger_left;
WORD trigger_top;
BYTE trigger_width;
BYTE trigger_height;
BYTE trigger_effect_id;
WORD animation_frames_base_loc;
WORD preview_image_index;
WORD unknown3;
BYTE trap_sound_effect_id;

First of all, a word on WORD and BYTE in groundXo.dat.  Unlike the .LVL file
format, WORDs in groundXo.dat are stored little-endian.  This means that the
lower byte is stored before the upper byte, in reverse to the way you'd
normally write down the value in binary or hex.  For example, the decimal
value 4660 when written in hex is 0x1234.  When stored as 2 bytes in
little-endian format, the 0x34 bytes comes first, followed by 0x12.

This little-endian format is native to the Intel instruction set, so if you
read the bytes in this order directly into a 16-bit int variable, the int
variable will contain the correct value.

So, an explanation of each field.  Actually I haven't verified many of them,
so some of the information below might be incomplete or inaccurate, but anyhow:

width, height, animation_frames_base_loc, animation_frame_data_size,
mask_offset_from_image, start_animation_frame_index,
end_animation_frame_index, preview_image_index:

I have to explain all these fields at once because they are interrelated.
Width and height of course are the width and height of a single animation
frame bitmap.  animation_frames_base_loc is the offset from the start of the
data section in vgagrX.dat which contains the bitmaps for objects.  Remember
that the object bitmaps are always in the second data section of vgagrX.dat.
animation_frames_base_loc points to the start of all the bitmap data for the
object in question.

animation_frame_data_size is how many bytes in individual animation frame
bitmap takes.  To be more precise, it specifies the offset in bytes from one
animation frame bitmap to the next one.  In other words, the first animation
frame is the animation_frame_data_size number of bytes starting from
animation_frames_base_loc.  The second animation frame is the
animation_frame_data_size number of bytes starting from
animation_frames_base_loc + 1 * animation_frame_data_size.  The third
animation frame is the animation_frame_data_size number of bytes starting from
animation_frames_base_loc + 2 * animation_frame_data_size.  And so forth.

start_animation_frame_index and end_animation_frame_index refers to which
frame to start off the animation from, and end_animation_frame_index refers to
the last animation frame of the object.  Animation frames are numbered from 0
up, so end_animation_frame_index in effect tells us how many animation frames
total there are for this object.  For continous looping animation, when you
get to the last frame of animation it goes back to animation frame #0.  For
triggered animations, when you get to the last frame of animation, on the next
frame it will display the start_animation_frame_index-th frame (I think; or
maybe it's just frame #0) and animation stops there until it's triggered
again.  preview_image_index points to the animation frame used when rendering
the level preview you see at the level info screen you get right (the one that
also tells you the title, how many out and % to save) before the game starts
the level.  (It is a full-size animation frame despite being used for the
level preview; the level preview shrinks everything down automatically.)

Finally, mask_offset_from_image.  Each frame of animation really comprises of
2 bitmaps.  One is the 16-color bitmap you expect.  However, in order to
represent the concept of transparent pixels, a separate monochrome mask bitmap
is also necessary.  The mask bitmap specifies which pixels are really the
object's pixels, and which pixels are instead the background's pixels and so
should be transparent.  Each 1 bit in the mask stands for a solid pixel, and
each 0 means transparent background.  But anyway, the mask_offset_from_image
tells you the offset from the start of whatever animation frame you are in to
get the corresponding mask.  So for example, for frame #0, the 16-color bitmap
is located at animation_frames_base_loc, so the corresponding mask for frame
#0 is at
    animation_frames_base_loc
    + mask_offset_from_image.
Similarly, for frame #5, the 16-color bitmap is located at
    animation_frames_base_loc
    + 5 * animation_frame_data_size,
so the corresponding mask bitmap for frame #5 is at
    animation_frames_base_loc
    + 5 * animation_frame_data_size
    + mask_offset_from_image.
With these fields, you now have more than enough information to display the
objects of a level for level-editor purposes.  The remaining fields contains
additional information the game uses:


animation_flags:  Most of this WORD seems to be unused, and I _think_ the
unused bits are all 0s.  Bit 0 appears to be set to 0 for animations that
loops continously (eg. water, the coal pits, the spinning trap of death), and
to 1 for animations that only plays when the object is "triggered" in some
fashion (eg. most of the traps).  I'm not sure what it does for objects that
don't animate, but I suppose objects that don't animate can be interpreted as
a continous loop animation with a single animation frame.  I think bit 1 might
also do something but I'm not sure.


trigger_left, trigger_top, trigger_width, trigger_height, trigger_effect_id:

These parameters describes the rectangular trigger area for the object and the
trigger effect.  The trigger effect of the object only takes place when the
lemming is within the rectangular trigger area.  Trigger effects can be things
like "exit", "drowned", or "death-by-trap".  You'd notice for example that to
exit, it is not enough for the lemming to merely reach the edges of the exit
bitmap, he has to go to somewhere in the middle before the "exit" effect takes
place.  The trigger area of the exit object is the mediator of where within
the object bitmap the effects of the object take place.

That being said, beware that the numbers are encoded slightly.  So if I use
left, top, width and height to denote the true location and dimensions of the
trigger area, this is how they relate:

left = trigger_left * 4
top = trigger_top * 4 - 4
width = trigger_width * 4
height = trigger_height * 4

At least I think this is how they work, although I'm slightly unsure about the
"- 4" in the formula for top.  Note that the location (left, top) is relative
to the position of the top-left corner of the object's bitmap.  Actually, to
be more precise, it is relative to the position of the top-left corner of the
object's bitmap with the x and y coordinates of the object's location rounded
down to the closest multiple of 4.  For objects the x coordinate needs to be a
multiple of 8 anyway, but you can specify any y coordinates.  This is why in
LemEdit you'll find that sometimes the exits "don't work" unless you lower its
position--this happens if Y is not a multiple of 4.  The problem stems from
the fact that the game uses a map with only a resolution of 4 pixels to keep
track of the various trigger areas.

One odd thing about the trigger area is that you cannot actually specify a
trigger_width and trigger_height of 0.  0 in those fields are actually treated
as a value of 256 it appears.  Instead, if you want to specify a null trigger
area, you specify a small trigger area (say 4x4), and set the
trigger_effect_id to a value that corresponds to "no effect".  Indeed, for all
objects that are merely decorative, the values are always set as follows:

trigger_left = 0, trigger_top = 0, trigger_width = 1, trigger_height = 1,
trigger_effect_id = 0

Finally, the trigger_effect_id.  This indicates the effect imposed on the
lemming who moves into the trigger area of the object.  It can be of the
following values:

0: no effect
1: exits level
4: triggered trap
5: drown
6: immediate disintegration
7: one-way wall, left
8: one-way wall, right
9: steel area (not actually used by any objects)

"triggered trap" refers to the class of traps where the trap does not animate
continously, but rather only animates when a lemming triggers it.  This
includes things like the beartrap, the 10-ton trap, etc.  The key
characteristic of this trap is that while the trap animation is playing, other
lemmings can pass through the trap unharmed.  Also of note is that the trap
animation graphics actually includes the lemming itself.  So in fact the game
immediately removes the killed lemming from the game when the trap is
triggered.  The lemming you see while the death animation is playing is
actually not the real one, but just part of the animation graphics of the
object.

"immediate disintegration" refers to the other type of traps where the lemming
"disintegrates" upon touching the trigger area.  The main difference being
that the death animation is not part of the object animation, and that more
than 1 lemming can be killed by the trap at once.  This type of trap include
things like the spinning-trap-of-death in the "pink" graphics set, the
fire-shooting traps in the "hell" graphics set, the coal pit trap in the
"hell" graphic set, etc.

"drown" of course refers to the water and lava traps, where upon touching the
trigger area, the lemming is drowned.  The logical effect is basically the
same as "immediate disintegration", just that the death animation is different.

You might note that there isn't an "entrance" effect, what gives?  Actually if
you think about it, entrances don't follow the "trigger effect" model.
Entrances don't take effect by having a lemming go through it.  So in fact the
game hard-codes entrances to always be the first object id in any graphics
set, and the location within the entrance bitmap where the lemmings come out
from is also hardcoded (but unfortunately I don't have the values at hand).
In the graphics sets the game supplies, the entrance object's
trigger_effect_id is set to 0.

trap_sound_effect_id:  This describes the sound effect played when a trap of
trigger_effect_id = 4 is triggered.  It does not apply for other
trigger_effect_id's:  the game takes over for objects whose trigger_effect_id
is not 4 and so you don't get to select the sound effect.  Here are a list of
values (in hex) of the sound effects recognized by PC Lemmings/CustLemm:

00 = no sound
01 = skill select (the sound you get when you click on one of the skill icons
at the bottom of the screen)
02 = entrance opening (sounds like "boing")
03 = level intro (the "let's go" sound)
04 = the sound you get when you assign a skill to lemming
05 = the "oh no" sound when a lemming is about to explode
06 = sound effect of the electrode trap and zap trap,
07 = sound effect of the rock squishing trap, pillar squishing trap, and
spikes trap
08 = the "aargh" sound when the lemming fall down too far and splatters
09 = sound effect of the rope trap and slicer trap
0A = sound effect when a basher/miner/digger hits steel
0B = (not sure where used in game)
0C = sound effect of a lemming explosion
0D = sound effect of the spinning-trap-of-death, coal pits, and fire shooters
(when a lemming touches the object and dies)
0E = sound effect of the 10-ton trap
0F = sound effect of the bear trap
10 = sound effect of a lemming exiting
11 = sound effect of a lemming dropping into water and drowning
12 = sound effect for the last 3 bricks a builder is laying down

And finally there are the "unknownX" words.  I don't believe they are used in
the EGA/VGA versions of the game, but might be involved in the Tandy and CGA
versions of the game.  So I didn't really bother investigating those fields,
but I've noted that:

unknown1 always seem to = mask_offset_from_image
unknown2 always seem to = unknown1 / 2

Not all 16 slots of OBJECT_INFO are used.  An unused slot is set to all 0s.
You can probably detect an unused slot if the bitmap width or height is 0.


TERRAIN_INFO
------------

A TERRAIN_INFO is 8 bytes, so the TERRAIN_INFO array takes up a total of 8*64
= 512 bytes.  The structure of a TERRAIN_INFO slot is as follows:

BYTE width;
BYTE height;
WORD image_loc;
WORD mask_loc;
WORD unknown1;

Thankfully, since terrain pieces are basically just a static bitmap, there are
far less metadata associated with them as compared with OBJECT_INFO.

width and height should be self explanatory.  image_loc and mask_loc refers to
the offset from the start of the data section.  The data section in question
is the second one in vgagrX.dat (recall that the second one contains the
object's bitmaps).  At offset image_loc is the 16-color bitmap for this
terrain piece, and at offset mask_loc is the mask bitmap for this terrain
piece.  unknown1 is probably related to the CGA/Tandy graphics which we don't
care about.

Again, not all 64 slots of TERRAIN_INFO are used.  An unused slot is set to
all 0s, and you can probably detect an unused slot if width or height is 0.


PALETTES
--------

Because the game runs in a 320x200x16 color graphics mode, to get decent
graphics it needs to modify the palette to a custom set of colors tailored for
the graphics set in question.  For example, to get all those shades of blue in
the "crystal" graphics set, many of the palette entries will have to be set to
shades of blue, and similarly for the other graphics sets where you'd notice a
dominate color.  (Indeed, it's probably because of the limit of 16 colors that
cause each graphics set to tend towards a particular dominate color.)

It turns out CGA and Tandy graphics modes cannot use palettes, so the palettes
contained in groundXo.dat are for the EGA and VGA modes.

An ega palette entry takes up a single byte, while a vga palette entry takes
up 3 bytes.  I'll notate the types as EGA_PAL_ENTRY and VGA_PAL_ENTRY
respectively.  (I'll explain how to interpret a palette entry later.)

And so the structure of the PALETTES section goes as follows:

EGA_PAL_ENTRY ega_custom[8];
EGA_PAL_ENTRY ega_standard[8];
EGA_PAL_ENTRY ega_preview[8];
VGA_PAL_ENTRY vga_custom[8];
VGA_PAL_ENTRY vga_standard[8];
VGA_PAL_ENTRY vga_preview[8];

First of all, the concept of a palette goes as follows.  As a 16-color mode,
each pixel has a value from 0 to 15.  This value indexes into a 16-entry
physical palette.  The physical palette specifies the actual color to display
corresponding to each of 0 to 15.  So although you only get to display 16
distinct colors at once, you get some flexibility regarding the set of colors
to use.

But it turns out the Lemmings game imposes further restrictions on the
palette.  It splits the 16-entry physical palette into two halves.  The lower
half, which corresponds to pixel values 0 to 7, are fixed by the game and
always use a fixed set of colors.  This is even though the PALETTES section
appears to contain a ega_stanard[8] and a vga_standard[8]; those palette
entries are actually not used by the game, as far as I know.  The upper half
corresponding to pixel values 8 to 15, are the ones that can vary from
graphics set to graphics set, because the values used are read from entries in
the PALETTES section.

In particular, suppose we're in VGA mode (the story is analogous for EGA
mode).  Then when rendering the level preview, the game uses the 8 entries in
the vga_preview array for the upper-half of the physical palette.  When
rendering the actual level (eg. what you'd expect to see in a level editor),
the game uses the 8 entries in the vga_custom array instead.  Although in
practice, I believe in all the graphics sets the game supplies, vga_custom and
vga_preview are identical.

Finally, how to intepret a palette entry.  First of all, I assume you
understand the concept of RGB for specifying a color.  If not look it up.

In a VGA_PAL_ENTRY, the first byte specifies the red component, the second
byte the green, and the third byte the blue.  Although a byte is used for each
color component, only the lower 6 bits of each byte are actually used.  This
is because the physical hardware of VGA only supports that many bits per color
component.  So (0x3F, 0x00, 0x00) gives you the brightest red you can get,
(0x00, 0x3F, 0x00) the brightest green, and (0x00, 0x00, 0x3F) the brightest
blue.  (0x3F, 0x3F, 0x3F) would be the brighest white.

Since nowadays graphics cards are capable of 24-bit color, the conversion from
a VGA_PAL_ENTRY to a 24-bit RGB color (where each color component gets 8 bits
instead of only 6) is simply 6-bit-component-value * 255 / 63 for each color
component.  (This sentence mainly applies only if you're planning to write a
Windows version of the level editor.)

In a EGA_PAL_ENTRY, you get only 2 bits per color component.  So only the
lower 6 bits of the 8 bits in a EGA_PAL_ENTRY are meaningful.  The bits are
organized as follows:  (unused) (unused) RH GH BH RL GL BL.  "RH" means the
higher bit of the red component, "RL" means the lower bit of the red
component, etc.  So for example, the 4 levels of red from brighest to darkest
(with darkest being actually the color black rather than red) would have the
values 0x24 0x20, 0x04, and 0x00 respectively (translate them into binary to
see how they involve the RH and RL bits).

Ah yes, before I forgot, here is the fixed, lower half of the physical palette
the game uses, specified in the VGA_PAL_ENTRY format:

  {0x00, 0x00, 0x00},  /* black */
  {0x10, 0x10, 0x38},  /* blue, used for the lemmings' bodies */
  {0x00, 0x2C, 0x00},  /* green, used for hair */
  {0x3C, 0x34, 0x34},  /* white, used for skin */
  {0x2C, 0x2C, 0x00},  /* dirty yellow, used in the skill panel */
  {0x3C, 0x08, 0x08},  /* red, used in the nuke icon */
  {0x20, 0x20, 0x20},  /* gray, used in the skill panel */
  (variable)

Ok, so I lied slightly that the the lower half is fixed.  In actuality, only
the first 7 entries are fixed.  But the last one is not copied from
vga_standard[7] as you'd expect.  Instead, I believe the game always copies
from vga_preview[0] or vga_custom[0] (whichever is used in the context of
question) to the "variable" entry.  So you don't get an additional color to
specify, since it is just a duplicate of one of your pickable colors.

An interesting thing to note about the "variable" color above, is that it is
the color used to render that mini-map you get at the lower-right corner when
you are playing a level, and also for rendering the bricks of a builder.



VGAGRx.DAT
----------

Recall once more that the first section of decompressed data is for the
bitmaps and masks of the terrain pieces, while the second section is for the
bitmaps and masks of the interactive objects.

The bitmap is a 4-bit planar bitmap, and the mask is a monochrome bitmap.  The
width, height, and location of all bitmaps are specified in GROUNDxo.DAT as
explained before.

These 4-bit bitmaps, i.e. 16 color bitmaps, are stored component-wise.
There are 4 monochrome bitmaps next to each other for one 16-color bitmap.
First comes a monochrome bitmap that describes the first bit of each pixel,
then another monochrome bitmap which describes all second bits, etc.  These
single-bit bitmaps are stored in little endian order, i.e. the first bitmap
adds 1 to each color, the second 2, then 4, then 8.  This means that the bits
for a single 4-bit pixel are scattered throughout the whole bitmap data.

Here's a curiosity about the terrain graphics.  The 16-color bitmaps for the
terrain only make use of the graphic-set-specific 8 colors, numbered 8 through
15.  Since the terrain uses a color >= 8 for each solid pixel and color 0, i.e.
black, for air, the last plane (that adds 8 to a pixel) is equal to the mask
plane.  If you actually look at the terrain metadata in groundX.dat, you will
see that the mask location is indeed identical to the last plane's location.
E.g. the crystal set's terrain piece 0 has a size of 0x20 times 0x20, which
means its 4-bit bitmap takes 0x20 * 0x20 * 4 bits = 0x1000 bits = 0x200 bytes
of storage space, but the mask location starts only 0x180 bytes behind the
image location's begin.

I believe the game nonetheless doesn't infer the mask from the black pixels,
but instead reads the mask information independently.  I also believe that the
game reads all four planes to get the color of a terrain piece, i.e. I don't
think it reads just the first three planes and then adds 8 to each solid pixel.
After all, it must read four-plane bitmaps anyway when making the special
objects; they use all 16 colors.

It's possible that the VGAGRx.DAT may contain additional bitmaps not related
to interactive objects or terrain pieces, but I don't know much about that.
Experiment and find out whether there are any gaps and if so whether they
contain any interesting graphics.  Note that just because there are additional
graphics doesn't necessarily mean that the game will use them.  MAIN.DAT
probably contains the remaining graphics the game actually uses, but I
currently don't know anything about that file.  However, if there are any
bitmaps in there, I can guarantee you they will be stored as planar bitmaps,
or as monochrome bitmaps if they are masks (eg. the masks used for digging,
bashing, explosion, etc.).  So with some experimentation you might be able to
discover some of the other bitmaps the game uses.

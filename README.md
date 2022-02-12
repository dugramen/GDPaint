# GDPaint
Godot Plugin for a simple sprite editor

This is my first plugin project. I'm not the best programmer so this is pretty sloppy code, but from testing it out, it seems pretty stable right now.
I'm also very new to Github projects in general, so I doubt I'm doing this right. :P

![Look at the GDPaint Editor](https://i.imgur.com/LPq3sPx.jpg)

Installation:

1. Unzip the GDPaint.zip file
1. Drag the "gd_paint" folder into your project's "addons" folder
1. Enable the plugin in Godot from Project->Project Settings->Plugins

Usage:
- Open a StreamTexture in the inspector, and there will be a button to edit it in GDPaint.
- The sprite editor is on the bottom panel, so it can just be clicked on as well.

***Note: It's important that your cursor is in the GDPaint Editor window when using keyboard commands, as it will consume input events only while the cursor is inside. 
      If you try commands like Ctrl+z or Ctrl+x while the cursor is outside, it will trigger the respective commands of the Godot Editor, which could be problematic.***

## Current features

### Tools
- Brush
- Line
- Rect & Rect_fill
- Square & Square_fill
- Ellipse & Ellipse_fill
- Circle & Circle_fill
- Fill (Paint Bucket)
- Color Picker
- Selection:
  - Restrict drawing area
  - Ctrl + X to cut pixels in a selection
- Stamp:
  - Paste any cut selection
- Flip X & Flip Y (Mirroring)

### Navigation and Shortcuts
- Hold space and move the mouse to pan the image
- Scroll up and down to zoom in and out
- Ctrl+Z to undo paint
- Ctrl+Shift+Z to redo paint
- Hold Shift anytime to draw a line
- Hold Ctrl anytime to draw a rect
- Hold Ctrl+Shift anytime to draw a filled rect
- Hold Alt anytime to color pick

### Other
- Custom Grid size
- Grid Snapping
- Image cropping and resizing
- Saving and Loading as png files only
- Color Palette

### Planned Features
- Layer support
- Animation frames support
- Better selection tool, with handles and resizing
- Tool specific options, like brush size and pixel perfect
- Shader support
- Better organization of the editor
- Better orginization of code
- Better undo/redo 
- Possible file drag and drop support 


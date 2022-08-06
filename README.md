# GDPaint
A Sprite Editing tool for Godot 

(web demo available at https://dugtrioramen.itch.io/gd-paint-v2)

<!-- ![Look at the GDPaint Editor](https://i.imgur.com/LPq3sPx.jpg) -->
![program-screen](https://user-images.githubusercontent.com/54819319/182956410-08330231-8c59-4e4d-a64e-faf6e476003f.jpg)


Installation:

1. Unzip the GDPaint.zip file
1. Drag the "gd_paint" folder into your project's "addons" folder
1. Enable the plugin in Godot from Project->Project Settings->Plugins

Usage:
- Open a StreamTexture in the inspector, and there will be a button to edit it in GDPaint.
- The sprite editor is on the top panel, so it can just be clicked on as well.

***Note: It's important that your cursor is in the GDPaint Editor window when using keyboard commands, as it will consume input events only while the cursor is inside. 
      If you try commands like Ctrl+z or Ctrl+x while the cursor is outside, it will trigger the respective commands of the Godot Editor.***

## Current features

### Drawing Tools
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

### Helpful Features
- Shortcut to open in GD Script from Godot's Texture inspector
- Undo & Redo
- Layering & Animation support
- Draw while animating (for easily making trail animations)
- Pixel Perfect brush
- Circle, Square, and Line Brushes with custom size & rotation
- Flip X & Flip Y (Mirroring)
- Tiled Mode (for help with draing repeating/tiled textures)
- Custom Grid Size
- Grid Snapping
- Image cropping and resizing with different quality options
- Foldable and Rearrangeable UI (drag and drop)

### Navigation and Keyboard Shortcuts
- Hold space and move the mouse to pan the image
- Scroll up and down to zoom in and out
- Ctrl+Z to undo paint
- Ctrl+Shift+Z to redo paint
- Hold Shift anytime to draw a line
- Hold Ctrl anytime to draw a rectangle
- Hold Ctrl+Shift anytime to draw a filled rectangle
- Hold Alt anytime to color pick

### Planned Features
- [x] Layer support (v2)
- [x] Animation frames support (v2)
- [x] Better selection tool, with handles and resizing (v2)
- [x] Tool specific options, like brush size and pixel perfect (v2)
- [ ] Shader support
- [ ] Better organization of the editor
- [ ] Better orginization of code
- [ ] Better undo/redo 
- [ ] Possible file drag and drop support 


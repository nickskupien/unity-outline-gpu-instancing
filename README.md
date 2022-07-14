# Depth and Normals
used for testing outlines using depth and normals.

however this expanded into gpu instanced pixel art grass on toon shaded terrain.

more will be updated in the future to create a pixel art render pipeline!

## Demos of this project

Rendering 100,000 blades of blades of grass (for fun) all using custom shaders: to process the grass quickly in batches, and to add pixel art rendering techniques (toon shader, outline shader, pixelized effect (applied to grass individually), shader to rotate the 2D grass so it faces the camera)

https://user-images.githubusercontent.com/37463260/179023832-12f26091-ce08-42a2-bd29-8741fca7f382.mov


Demo of 100,000 quads (2D squares) taking only 4 cycles on the gpu to render. This was accomplished using a propery called gpu instancing, where thousands of gpu cores are used to compute the squares position and rotation in bulk called 'batching'. To do this I used a shared buffer between the gpu and cpu to send data over. I have two helpers on the gpu. 1 is modifying the buffer to adjust the rotation to match the camera. 2 is rendering the quads. All the cpu needs to do each cycle is send one matrix with the rotation of the camera. looking at the render thread time it is less than a millisecond each frame. This is almost like having nothing running at all

https://user-images.githubusercontent.com/37463260/179024284-cb181eb1-1746-4cff-8374-bc7b128a90b2.mov

Note the framerate (locked at 60fps) and the gpu processing time (~0.8ms). All rendering and position calculation done on the gpu. Without this process the framerate would hardly be 1fps with 120ms gpu computation time.


A demo of a custom shader which uses normal maps (a view of the screen where colour represents which direction each side of a polygon faces) and depth maps (a view of the screen where colour represents the depth) to determine single pixel outlines around objects. This is applied post rendering using the sobel filter algorithm.

https://user-images.githubusercontent.com/37463260/179027842-5e15883e-1cb5-4830-af8e-8e36f08e1226.mov

Note the dark outline for outer edges and the light outline for inner edge


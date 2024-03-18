# CSCI 5619 Final Project
**Samyok Nepal and Jasmine DeGuzman**

![flexiblespaces.png](./flexiblespaces.png)

For our final project, we decided that we wanted to create an implementation of [Flexible Spaces](https://ieeexplore.ieee.org/document/6549386#full-text-section). 
This is redirection technique extends the the previous work done on Impossible Spaces and change blindness by generalizing the algorithm for dynamic layout generation by automatic rerouting through the 
virtual environment. 

## Description
In the original paper, the corridors are defined as a changeable part of the environment that is rerouted every time the user leaves a room.
The rerouting algorithm randomly selects an intermediate point I between the start position S, defined by the door of the current room, and the 
end position E, defined by the door of the destination room. In order to connect these points, additional randomly selected points are defined between S and I,
as well as I and E.

We found that trying to follow this algorithm outlined in the Flexible Spaces literature did not create a valid path because of how the path would intersect the rooms. We instead used a classic breadth-first search in order to find the shortest path between rooms which were represented as integer lattice points. There were some other criteria that was needed for a path to be considered valid. The first point of the hallway was 1 unit out from the door fo the current room in order to guarantee a point where the hallway and room walls do not intersect. The first three points of the path could not be in the current room and the last three points could not be in the destination room, otherwise it would break the illusion. Our implementation also utilizes portals for transitioning between the rooms and the hallway. By doing so, we were able to associate crossing through the portal with the spawning/despawning of walls. 

## Development Environment
This project was created using Godot 4.3.0 and the XR tools plugin. It was developed for the Meta Quest 2 headset.

## Third Party Assets
We used a Minecraft theme for the Flexible Space demo. All of our textures were taken from the [Minecraft Wiki]{https://minecraft.fandom.com/wiki/Minecraft_Wiki). Specifically we used the [Nether Portal](https://minecraft.fandom.com/wiki/Nether_portal) for the door of each room and [Iron Ingot](https://minecraft.fandom.com/wiki/Iron_Ingot) for the walls.

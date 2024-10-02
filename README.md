---

# Patch-Match for Hole Filling

This repository implements the Patch-Match algorithm for image hole filling. The technique allows for efficient filling of missing regions in an image by finding and copying similar patches from the surrounding areas.

## Features
- MATLAB implementation of Patch-Match
- Includes functions for nearest neighbor search and hole-filling
- Sample input images and outputs for testing

## Files
- `patchMatchNNFHole.m`: Core function for hole filling
- `voteNNFHole.m`: Voting mechanism for final patch selection
- `HoleFilling.m`: Runner File

## Sample Input
![Alt Text](/test_inputs/testimgoriginal.png)
![Alt Text](/test_inputs/testimg.png)

## Sample Output
![Alt Text](/test_outputs/testimgout.png)

## How to Use
1. Clone the repository: 
   ```bash
   git clone https://github.com/peterlototsky/Patch-Match.git
   ```
2. Open MATLAB and navigate to the project.
3. Run HoleFilling.m 

--- 

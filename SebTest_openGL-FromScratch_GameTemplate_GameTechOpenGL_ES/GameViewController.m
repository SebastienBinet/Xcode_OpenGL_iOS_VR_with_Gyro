//
//  GameViewController.m
//  
//
//  Created by Sebastien Binet on 2015-10-08.
//  Copyright © 2015 Sebastien Binet. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>

///////////////////// Test Sbinet for motion
#import <CoreMotion/CoreMotion.h>
CMMotionManager *MyCMMotionManager;
///////////////////// Test Sbinet for motion - end

///////////////////// Test Sbinet for skybox
#include "Brudslojan_skybox_image_416x312_3_BytesPerPixel.h"
///////////////////// Test Sbinet for skybox- end


#define OBJECTS_CENTER_COORD                        0.0f, -1.0f, 4.0f
#define SHOULD_TURN_ALL_OBJECTS_AROUND_FIXED_POINT  false
#define SHOULD_MOVE_ALL_OBJECTS_AROUND_FIXED_POINT  false
#define USE_SKY_BOX_INSTEAD_OF_2_SMALL_CUBES        true
#define _____ALWAYS_PUT_TO_false_BECAUSE_BROKEN_____USE_TEXTURE___                                 false
#define ADD_CHECKERBOARD_TEXTURE     true



#define BUFFER_OFFSET(i) ((char *)NULL + (i))
// next one is from Joey Adams in http://stackoverflow.com/questions/3553296/c-sizeof-single-struct-member
#define member_size(type, member) sizeof(((type *)0)->member)

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    // NORMALS ARE NOT USED IN THIS TEST VERSION -  UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    // NORMALS ARE NOT USED IN THIS TEST VERSION -  ATTRIB_NORMAL,
    ATTRIB_TEXTURE,
    ATTRIB_OBJECT_NUMBER,
    NUM_ATTRIBUTES
};


//GLfloat bigArrayForGeometryAndTexture[1];


const int tileMultiplier = 1;
const float maxUV = 1.0f * tileMultiplier;


#if ADD_CHECKERBOARD_TEXTURE
//#define NUMBER_SQUARES_IN_WORLD      (1 /* unfold skybox on a square*/     + 6 /*  6 side of skybox */     + 6 /*   6 sides of a cube */ )
#define NUMBER_VERTICES_PER_TRIANGLE  3
#define NUMBER_TRIANGLE_PER_SQUARE    2
#define NUMBER_TRIANGLES_IN_WORLD     (                                                  \
                                        (   1 /*  1 square  to show the unfold skybox*/  \
                                          + 6 /*  6 squares of skybox */                 \
                                          + 6 /*  6 squares of a cube */                 \
                                        )                                                \
                                        * NUMBER_TRIANGLE_PER_SQUARE                     \
                                      )


#define NUMBER_VERTICES_IN_WORLD      ( NUMBER_TRIANGLES_IN_WORLD   *   NUMBER_VERTICES_PER_TRIANGLE )


#define NUMBER_FLOAT_PER_POS          3 // PosX, PosY, PosZ
#define NUMBER_FLOAT_PER_NORMAL       3 // NormX, NormY, NormZ
#define NUMBER_FLOAT_PER_UV           2 // U, V

#define NUMBER_FLOAT_PER_VERTEX       ( NUMBER_FLOAT_PER_POS  +  NUMBER_FLOAT_PER_NORMAL  +  NUMBER_FLOAT_PER_UV )

#define NUMBER_FLOAT_PER_TRIANGLE  ( NUMBER_VERTICES_PER_TRIANGLE  *  NUMBER_FLOAT_PER_VERTEX )
//#define NUMBER_FLOATS_IN_WORLD       (NUMBER_OF_FLOAT_PER_TRIANGLE  *  NUMBER_TRIANGLE_PER_SQUARE  *  NUMBER_SQUARES_IN_WORLD)
#define NUMBER_FLOATS_IN_WORLD        ( NUMBER_FLOAT_PER_TRIANGLE  *  NUMBER_TRIANGLES_IN_WORLD )



int test[NUMBER_FLOATS_IN_WORLD];
int test2[( NUMBER_FLOATS_IN_WORLD  *  NUMBER_TRIANGLES_IN_WORLD )];
int test3[( NUMBER_FLOATS_IN_WORLD  *  NUMBER_TRIANGLES_IN_WORLD )];


#define UV_VERTEX__1 0.00, 0.34
#define UV_VERTEX__2 0.26, 0.34
#define UV_VERTEX__3 0.49, 0.34
#define UV_VERTEX__4 0.75, 0.34
#define UV_VERTEX__5 1.00, 0.34
#define UV_VERTEX__6 0.00, 0.66
#define UV_VERTEX__7 0.26, 0.66
#define UV_VERTEX__8 0.49, 0.66
#define UV_VERTEX__9 0.75, 0.66
#define UV_VERTEX_10 1.00, 0.66
#define UV_VERTEX_11 0.26, 0.00
#define UV_VERTEX_12 0.49, 0.00
#define UV_VERTEX_13 0.26, 1.00
#define UV_VERTEX_14 0.49, 1.00

//const float SKY_BOX_SCALE = 10.0f;

typedef struct {
    float x;
    float y;
    float z;
} XYZ_t;

typedef struct {
    float u;
    float x;
} UV_t;

typedef struct {
    XYZ_t vertexPos;
    XYZ_t vertexNorm;
    UV_t  vertexUvMapping;
} vertexFullInfo_t;
#define OFFSET_IN_BYTES_TO_ACCESS_VERTEX_POS  0
#define OFFSET_IN_BYTES_TO_ACCESS_VERTEX_NORM ( member_size(vertexFullInfo_t,vertexPos) )
#define OFFSET_IN_BYTES_TO_ACCESS_VERTEX_UV   ( member_size(vertexFullInfo_t,vertexPos) + member_size(vertexFullInfo_t,vertexNorm ) )


typedef vertexFullInfo_t triangleFullInfo_t[NUMBER_VERTICES_PER_TRIANGLE];


triangleFullInfo_t g_allWorldInfo[ NUMBER_TRIANGLES_IN_WORLD ] =
{
    // Data layout for each line below is:
    // { positionX, positionY, positionZ },    { normalX, normalY, normalZ },       { U,    V }
    
    // Unrolled skybox image
    {
      { {  0.5f,       -0.4f,        -0.4f },        { 1.0f, -1.0f, -1.0f },      {  0.00,   maxUV } },
      { {  0.5f,       -0.1f,        -0.4f },        { 1.0f,  1.0f, -1.0f },      {  0.00,   0.00 } },
      { {  0.5f,       -0.4f,         0.4f },        { 1.0f, -1.0f,  1.0f },      {  maxUV,  maxUV } }
    },
    {
      { {  0.5f,       -0.4f,         0.4f },        { 1.0f, -1.0f,  1.0f },      { maxUV,  maxUV } },
      { {  0.5f,       -0.1f,        -0.4f },        { 1.0f,  1.0f, -1.0f },      {  0.00,   0.00 } },
      { {  0.5f,       -0.1f,         0.4f },        { 1.0f,  1.0f,  1.0f },      { maxUV,   0.00 } }
    },
    

    
    

    //           11-----12                        0.00
    //        -x+y-z  -x+y+z
    //           |   y   |
    //           |       |
    //   1-------2-------3-------4-------5        0.33
    //-x+y-z  +x+y-z  +x+y+z  -x+y+z  -x+y-z
    //   |  -z   |   x   |   z   |  -x   |
    //   |       |       |       |       |
    //   6-------7-------8-------9------10        0.66
    //-x-y-z  +x-y-z  +x-y+z  -x-y+z  -x-y-z
    //           |  -y   |
    //           |       |
    //           13-----14                        1.00
    //        -x-y-z  -x-y+z
    //
    //                                          \ U
    //   0       0       0       0       1     V
    //   .       .       .       .       .
    //   0       2       5       7       0
    //   0       5       0       5       0

    //
    // SKYBOX
    //             ^
    //             |
    //            +y
    //
    //   <- -z    +x     +z ->
    //
    
    // x
    {
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 1.0f, -1.0f, -1.0f},      { UV_VERTEX__7} },
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 1.0f,  1.0f, -1.0f},      { UV_VERTEX__2} },
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_VERTEX__8} }
    },
    {
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_VERTEX__8} },
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 1.0f,  1.0f, -1.0f},      { UV_VERTEX__2} },
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 1.0f,  1.0f,  1.0f},      { UV_VERTEX__3} }
    },
    
    // y
    {
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_VERTEX__2} },
    /*11*/      { {-5.0f,      5.0f,         -5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_VERTEX_11} },
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_VERTEX__3} }
    },
    {
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_VERTEX__3} },
    /*11*/      { {-5.0f,      5.0f,         -5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_VERTEX_11} },
    /*12*/      { {-5.0f,      5.0f,          5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_VERTEX_12} }
    },
    
    // -x
    {
    /* 5*/      { {-5.0f,      5.0f,         -5.0f},       {-1.0f,  1.0f, -1.0f},      { UV_VERTEX__5} },
    /*10*/      { {-5.0f,     -5.0f,         -5.0f},       {-1.0f, -1.0f, -1.0f},      { UV_VERTEX_10} },
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_VERTEX__4} }
    },
    {
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_VERTEX__4} },
    /*10*/      { {-5.0f,     -5.0f,         -5.0f},       {-1.0f, -1.0f, -1.0f},      { UV_VERTEX_10} },
    /* 9*/      { {-5.0f,     -5.0f,          5.0f},       {-1.0f, -1.0f,  1.0f},      { UV_VERTEX__9} }
    },
    
    // -y
    {
    /*13*/      { {-5.0f,     -5.0f,         -5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_VERTEX_13} },
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_VERTEX__7} },
    /*14*/      { {-5.0f,     -5.0f,          5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_VERTEX_14} }
    },
    {
    /*14*/      { {-5.0f,     -5.0f,          5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_VERTEX_14} },
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_VERTEX__7} },
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_VERTEX__8} }
    },

    // z
    {
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 1.0f,  1.0f,  1.0f},      { UV_VERTEX__3} },
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_VERTEX__4} },
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_VERTEX__8} }
    },
    {
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_VERTEX__8} },
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_VERTEX__4} },
    /* 9*/      { {-5.0f,     -5.0f,          5.0f},       {-1.0f, -1.0f,  1.0f},      { UV_VERTEX__9} }
    },
    
    // -z
    {
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_VERTEX__7} },
    /* 6*/      { {-5.0f,     -5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_VERTEX__6} },
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_VERTEX__2} }
    },
    {
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_VERTEX__2} },
    /* 6*/      { {-5.0f,     -5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_VERTEX__6} },
    /* 1*/      { {-5.0f,      5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_VERTEX__1} }
    }
};

// TO DELETE
//const XYZ_t verticesInfoUnitBox[] = {
//    //                  x,       y,       z
//    /*vertex [ 1]*/   { 0.5f,   -0.5f,    0.5f},
//    /*vertex [ 2]*/   { 0.5f,    0.5f,    0.5f},
//    /*vertex [ 3]*/   {-0.5f,    0.5f,    0.5f},
//    /*vertex [ 4]*/   {-0.5f,   -0.5f,    0.5f},
//    /*vertex [ 5]*/   { 0.5f,   -0.5f,    0.5f},
//    /*vertex [ 6]*/   { 0.5f,   -0.5f,   -0.5f},
//    /*vertex [ 7]*/   { 0.5f,    0.5f,   -0.5f},
//    /*vertex [ 8]*/   {-0.5f,    0.5f,   -0.5f},
//    /*vertex [ 9]*/   {-0.5f,   -0.5f,   -0.5f},
//    /*vertex [10]*/   { 0.5f,   -0.5f,   -0.5f},
//    /*vertex [11]*/   { 0.5f,   -0.5f,    0.5f},
//    /*vertex [12]*/   {-0.5f,   -0.5f,    0.5f},
//    /*vertex [13]*/   { 0.5f,   -0.5f,   -0.5f},
//    /*vertex [14]*/   {-0.5f,   -0.5f,   -0.5f}
//};
//
//const XYZ_t pos_SKYBOX_____[] = {
//    /*vertex [ 1]*/   { SKY_BOX_SCALE  *  SKY_BOX_SCALE,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 1].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 1].z},
//    /*vertex [ 2]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 2].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 2].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 2].z},
//    /*vertex [ 3]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 3].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 3].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 3].z},
//    /*vertex [ 4]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 4].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 4].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 4].z},
//    /*vertex [ 5]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 5].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 5].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 5].z},
//    /*vertex [ 6]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 6].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 6].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 6].z},
//    /*vertex [ 7]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 7].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 7].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 7].z},
//    /*vertex [ 8]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 8].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 8].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 8].z},
//    /*vertex [ 9]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 9].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 9].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 9].z},
//    /*vertex [10]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[10].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[10].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[10].z},
//    /*vertex [11]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[11].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[11].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[11].z},
//    /*vertex [12]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[12].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[12].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[12].z},
//    /*vertex [13]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[13].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[13].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[13].z},
//    /*vertex [14]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[14].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[14].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[14].z}
//};
//
//#define POS_XYZ_VERTEX__1     SKY_BOX_SCALE  *  verticesInfoUnitBox[1].x,    SKY_BOX_SCALE  *  verticesInfoUnitBox[1].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[1].z



// TO DELETE
//GLfloat gCubeVertexData[ NUMBER_FLOATS_IN_WORLD ] =
//{
//    // Data layout for each line below is:
//    // positionX, positionY, positionZ,     normalX, normalY, normalZ,        U,    V
//
//    // Unrolled skybox image
//    -0.5f,       -0.0f,        -0.0f,        1.0f, -1.0f, -1.0f,       0.00,   0.00,
//    -0.5f,        0.3f,        -0.0f,        1.0f,  1.0f, -1.0f,      maxUV,   0.00,
//    -0.5f,       -0.0f,         0.3f,        1.0f, -1.0f,  1.0f,       0.00,  maxUV,
//    
//    -0.5f,       -0.0f,         0.3f,        1.0f, -1.0f,  1.0f,       0.00,  maxUV,
//    -0.5f,        0.3f,        -0.0f,        1.0f,  1.0f, -1.0f,      maxUV,   0.00,
//    -0.5f,        0.3f,         0.3f,        1.0f,  1.0f,  1.0f,      maxUV,  maxUV,
//
//
//    
//    
//    
//    
//    
//    
//    
//    
//    //           11-----12                        1.00
//    //         x-y z  -x-y z
//    //           |   z   |
//    //           |       |
//    //   1-------2-------3-------4-------5        0.66
//    // x-y z   x y z  -x y z  -x-y z   x-y z
//    //   |   x   |   y   |  -x   |  -y   |
//    //   |       |       |       |       |
//    //   6-------7-------8-------9------10        0.33
//    // x-y-z   x y-z  -x y-z  -x-y-z   x-y-z
//    //           |  -z   |
//    //           |       |
//    //           13-----14                        0.00
//    //         x-y-z  -x-y-z
//    //
//    //                                          \ U
//    //   0       0       0       0       1     V
//    //   .       .       .       .       .
//    //   0       2       5       7       0
//    //   0       5       0       5       0
//    
//    //
//    // SKYBOX
//    //
//    
//    // x
//    /* 6*/      5.0f,     -5.0f,        -5.0f,        1.0f, -1.0f, -1.0f,      UV_VERTEX__6,
//    /* 7*/      5.0f,      5.0f,        -5.0f,        1.0f,  1.0f, -1.0f,      UV_VERTEX__7,
//    /* 1*/      5.0f,     -5.0f,         5.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX__1,
//    /* 1*/      5.0f,     -5.0f,         5.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX__1,
//    /* 7*/      5.0f,      5.0f,        -5.0f,        1.0f,  1.0f, -1.0f,      UV_VERTEX__7,
//    /* 2*/      5.0f,      5.0f,         5.0f,        1.0f,  1.0f,  1.0f,      UV_VERTEX__2,
//    
//    // y
//    /* 7*/      5.0f,      5.0f,        -5.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__7,
//    /* 8*/     -5.0f,      5.0f,        -5.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__8,
//    /* 2*/      5.0f,      5.0f,         5.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__2,
//    /* 2*/      5.0f,      5.0f,         5.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__2,
//    /* 8*/     -5.0f,      5.0f,        -5.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__8,
//    /* 3*/     -5.0f,      5.0f,         5.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__3,
//    
//    // -x
//    /* 8*/     -5.0f,      5.0f,        -5.0f,       -1.0f,  1.0f, -1.0f,      0.00,  0.00,
//    /* 9*/     -5.0f,     -5.0f,        -5.0f,       -1.0f, -1.0f, -1.0f,      0.00,  0.00,
//    /* 3*/     -5.0f,      5.0f,         5.0f,       -1.0f,  1.0f,  1.0f,      0.00,  0.00,
//    /* 3*/     -5.0f,      5.0f,         5.0f,       -1.0f,  1.0f,  1.0f,      0.00,  0.00,
//    /* 9*/     -5.0f,     -5.0f,        -5.0f,       -1.0f, -1.0f, -1.0f,      0.00,  0.00,
//    /* 4*/     -5.0f,     -5.0f,         5.0f,       -1.0f, -1.0f,  1.0f,      0.00,  0.00,
//    
//    // -y
//    /*  */     -5.0f,     -5.0f,        -5.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */      5.0f,     -5.0f,        -5.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */     -5.0f,     -5.0f,         5.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */     -5.0f,     -5.0f,         5.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */      5.0f,     -5.0f,        -5.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */      5.0f,     -5.0f,         5.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    
//    // z
//    /* 2*/      5.0f,      5.0f,         5.0f,        1.0f,  1.0f,  1.0f,      UV_VERTEX__2,
//    /* 3*/     -5.0f,      5.0f,         5.0f,       -1.0f,  1.0f,  1.0f,      UV_VERTEX__3,
//    /*11*/      5.0f,     -5.0f,         5.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX_11,
//    /*11*/      5.0f,     -5.0f,         5.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX_11,
//    /* 3*/     -5.0f,      5.0f,         5.0f,       -1.0f,  1.0f,  1.0f,      UV_VERTEX__3,
//    /*12*/     -5.0f,     -5.0f,         5.0f,       -1.0f, -1.0f,  1.0f,      UV_VERTEX_12,
//    
//    // -z
//    /*13*/      5.0f,     -5.0f,        -5.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX_13,
//    /*14*/     -5.0f,     -5.0f,        -5.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX_14,
//    /* 7*/      5.0f,      5.0f,        -5.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX__7,
//    /* 7*/      5.0f,      5.0f,        -5.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX__7,
//    /*14*/     -5.0f,     -5.0f,        -5.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX_14,
//    /* 8*/     -5.0f,      5.0f,        -5.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX__8,
//    
//    
//    
//    
//    
//    
//    //
//    // SMALL CUBE
//    //
//    
//    // x
//    /* 6*/  0.5f - 1, -0.5f - 1,        -5.0f,        1.0f, -1.0f, -1.0f,      UV_VERTEX__6,
//    /* 7*/  0.5f - 1,  0.5f - 1,        -5.0f,        1.0f,  1.0f, -1.0f,      UV_VERTEX__7,
//    /* 1*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX__1,
//    /* 1*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX__1,
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        1.0f,  1.0f, -1.0f,      UV_VERTEX__7,
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        1.0f,  1.0f,  1.0f,      UV_VERTEX__2,
//    
//    // y
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__7,
//    /* 8*/ -0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__8,
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__2,
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__2,
//    /* 8*/ -0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__8,
//    /* 3*/ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_VERTEX__3,
//    
//    // -x
//    /*  */ -0.5f - 1,  0.5f - 1, -0.5f + 4.0f,       -1.0f,  1.0f, -1.0f,      0.00,  0.00,
//    /*  */ -0.5f - 1, -0.5f - 1, -0.5f + 4.0f,       -1.0f, -1.0f, -1.0f,      0.00,  0.00,
//    /*  */ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,       -1.0f,  1.0f,  1.0f,      0.00,  0.00,
//    /*  */ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,       -1.0f,  1.0f,  1.0f,      0.00,  0.00,
//    /*  */ -0.5f - 1, -0.5f - 1, -0.5f + 4.0f,       -1.0f, -1.0f, -1.0f,      0.00,  0.00,
//    /*  */ -0.5f - 1, -0.5f - 1,  0.5f + 4.0f,       -1.0f, -1.0f,  1.0f,      0.00,  0.00,
//    
//    // -y
//    /*  */ -0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */  0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */ -0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */ -0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */  0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    /*  */  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        0.0f, -1.0f,  0.0f,      0.00,  0.00,
//    
//    // z
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        1.0f,  1.0f,  1.0f,      UV_VERTEX__2,
//    /* 3*/ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,       -1.0f,  1.0f,  1.0f,      UV_VERTEX__3,
//    /*11*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX_11,
//    /*11*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_VERTEX_11,
//    /* 3*/ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,       -1.0f,  1.0f,  1.0f,      UV_VERTEX__3,
//    /*12*/ -0.5f - 1, -0.5f - 1,  0.5f + 4.0f,       -1.0f, -1.0f,  1.0f,      UV_VERTEX_12,
//    
//    // -z
//    /*13*/  0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX_13,
//    /*14*/ -0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX_14,
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX__7,
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX__7,
//    /*14*/ -0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX_14,
//    /* 8*/ -0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_VERTEX__8
//
//};

#else

#define NUMBER_SQUARES_IN_WORLD                     12
#define NUMBER_FLOAT                                (NUMBER_SQUARES_IN_WORLD * 36)

GLfloat gCubeVertexData[NUMBER_FLOAT] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5f, -0.5f, -0.5f,        1.0f, -1.0f, -1.0f,
    0.5f, 0.5f - 1, -0.5f,         1.0f, 1.0f, -1.0f,
    0.5f, -0.5f, 0.5f,         1.0f, -1.0f, 1.0f
    ,
    0.5f, -0.5f, 0.5f,         1.0f, -1.0f, 1.0f,
    0.5f, 0.5f, -0.5f,         1.0f, 1.0f, -1.0f,
    0.5f, 0.5f, 0.5f,          1.0f, 1.0f, 1.0f
    ,
    
    0.5f, 0.5f, -0.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, 0.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, 0.5f,         0.0f, 1.0f, 0.0f
    ,

    -0.5f, 0.5f, -0.5f,        -1.0f, 1.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, -1.0f, -1.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 1.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 1.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,       -1.0f, -1.0f, -1.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, -1.0f, 1.0f
    ,
    
    -0.5f, -0.5f, -0.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, 0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -0.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, 0.5f,         0.0f, -1.0f, 0.0f
    ,

    0.5f, 0.5f, 0.5f,          1.0f, 1.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 1.0f, 1.0f,
    0.5f, -0.5f, 0.5f,         1.0f, -1.0f, 1.0f
    ,
    0.5f, -0.5f, 0.5f,         1.0f, -1.0f, 1.0f,
    -0.5f, 0.5f, 0.5f,         -1.0f, 1.0f, 1.0f,
    -0.5f, -0.5f, 0.5f,        -1.0f, -1.0f, 1.0f
    ,
    
    0.5f, -0.5f, -0.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f
    ,
    0.5f, 0.5f, -0.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -0.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,        0.0f, 0.0f, -1.0f
    ,







//    0.5f, -0.5f, -10.5f,        1.0f, -1.0f, -1.0f,
//    0.5f, 0.5f, -10.5f,         1.0f, 1.0f, -1.0f,
//    0.5f, -0.5f, 9.5f,         1.0f, -1.0f, 1.0f
//    ,
//    0.5f, -0.5f, 9.5f,         1.0f, -1.0f, 1.0f,
//    0.5f, 0.5f, -10.5f,         1.0f, 1.0f, -1.0f,
//    0.5f, 0.5f, 9.5f,          1.0f, 1.0f, 1.0f
//    ,
//    
//    0.5f, 0.5f, -10.5f,         0.0f, 1.0f, 0.0f,
//    -0.5f, 0.5f, -10.5f,        0.0f, 1.0f, 0.0f,
//    0.5f, 0.5f, 9.5f,          0.0f, 1.0f, 0.0f,
//    0.5f, 0.5f, 9.5f,          0.0f, 1.0f, 0.0f,
//    -0.5f, 0.5f, -10.5f,        0.0f, 1.0f, 0.0f,
//    -0.5f, 0.5f, 9.5f,         0.0f, 1.0f, 0.0f
//    ,
//    
//    -0.5f, 0.5f, -10.5f,        -1.0f, 1.0f, -1.0f,
//    -0.5f, -0.5f, -10.5f,       -1.0f, -1.0f, -1.0f,
//    -0.5f, 0.5f, 9.5f,         -1.0f, 1.0f, 1.0f,
//    -0.5f, 0.5f, 9.5f,         -1.0f, 1.0f, 1.0f,
//    -0.5f, -0.5f, -10.5f,       -1.0f, -1.0f, -1.0f,
//    -0.5f, -0.5f, 9.5f,        -1.0f, -1.0f, 1.0f
//    ,
//    
//    -0.5f, -0.5f, -10.5f,       0.0f, -1.0f, 0.0f,
//    0.5f, -0.5f, -10.5f,        0.0f, -1.0f, 0.0f,
//    -0.5f, -0.5f, 9.5f,        0.0f, -1.0f, 0.0f,
//    -0.5f, -0.5f, 9.5f,        0.0f, -1.0f, 0.0f,
//    0.5f, -0.5f, -10.5f,        0.0f, -1.0f, 0.0f,
//    0.5f, -0.5f, 9.5f,         0.0f, -1.0f, 0.0f
//    ,
//    
//    0.5f, 0.5f, 9.5f,          1.0f, 1.0f, 1.0f,
//    -0.5f, 0.5f, 9.5f,         -1.0f, 1.0f, 1.0f,
//    0.5f, -0.5f, 9.5f,         1.0f, -1.0f, 1.0f
//    ,
//    0.5f, -0.5f, 9.5f,         1.0f, -1.0f, 1.0f,
//    -0.5f, 0.5f, 9.5f,         -1.0f, 1.0f, 1.0f,
//    -0.5f, -0.5f, 9.5f,        -1.0f, -1.0f, 1.0f
//    ,
//    
//    0.5f, -0.5f, -10.5f,        0.0f, 0.0f, -1.0f,
//    -0.5f, -0.5f, -10.5f,       0.0f, 0.0f, -1.0f,
//    0.5f, 0.5f, -10.5f,         0.0f, 0.0f, -1.0f
//    ,
//    0.5f, 0.5f, -10.5f,         0.0f, 0.0f, -1.0f,
//    -0.5f, -0.5f, -10.5f,       0.0f, 0.0f, -1.0f,
//    -0.5f, 0.5f, -10.5f,        0.0f, 0.0f, -1.0f
//    ,

    0.5f, -0.5f, -2.5f,        1.0f, -1.0f, -1.0f,
    0.5f, 0.5f, -2.5f,         1.0f, 1.0f, -1.0f,
    0.5f, -0.5f, -1.5f,         1.0f, -1.0f, 1.0f
    ,
    0.5f, -0.5f, -1.5f,         1.0f, -1.0f, 1.0f,
    0.5f, 0.5f, -2.5f,         1.0f, 1.0f, -1.0f,
    0.5f, 0.5f, -1.5f,          1.0f, 1.0f, 1.0f
    ,
    
    0.5f, 0.5f, -2.5f,         0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -2.5f,        0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, -1.5f,          0.0f, 1.0f, 0.0f,
    0.5f, 0.5f, -1.5f,          0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -2.5f,        0.0f, 1.0f, 0.0f,
    -0.5f, 0.5f, -1.5f,         0.0f, 1.0f, 0.0f
    ,
    
    -0.5f, 0.5f, -2.5f,        -1.0f, 1.0f, -1.0f,
    -0.5f, -0.5f, -2.5f,       -1.0f, -1.0f, -1.0f,
    -0.5f, 0.5f, -1.5f,         -1.0f, 1.0f, 1.0f,
    -0.5f, 0.5f, -1.5f,         -1.0f, 1.0f, 1.0f,
    -0.5f, -0.5f, -2.5f,       -1.0f, -1.0f, -1.0f,
    -0.5f, -0.5f, -1.5f,        -1.0f, -1.0f, 1.0f
    ,
    
    -0.5f, -0.5f, -2.5f,       0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -2.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, -1.5f,        0.0f, -1.0f, 0.0f,
    -0.5f, -0.5f, -1.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -2.5f,        0.0f, -1.0f, 0.0f,
    0.5f, -0.5f, -1.5f,         0.0f, -1.0f, 0.0f
    ,
    
    0.5f, 0.5f, -1.5f,          1.0f, 1.0f, 1.0f,
    -0.5f, 0.5f, -1.5f,         -1.0f, 1.0f, 1.0f,
    0.5f, -0.5f, -1.5f,         1.0f, -1.0f, 1.0f
    ,
    0.5f, -0.5f, -1.5f,         1.0f, -1.0f, 1.0f,
    -0.5f, 0.5f, -1.5f,         -1.0f, 1.0f, 1.0f,
    -0.5f, -0.5f, -1.5f,        -1.0f, -1.0f, 1.0f
    ,
    
    0.5f, -0.5f, -2.5f,        0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -2.5f,       0.0f, 0.0f, -1.0f,
    0.5f, 0.5f, -2.5f,         0.0f, 0.0f, -1.0f
    ,
    0.5f, 0.5f, -2.5f,         0.0f, 0.0f, -1.0f,
    -0.5f, -0.5f, -2.5f,       0.0f, 0.0f, -1.0f,
    -0.5f, 0.5f, -2.5f,        0.0f, 0.0f, -1.0f

};

#endif
#define NUMBER_TRIANGLES                            (NUMBER_SQUARES_IN_WORLD * 2)
#define NUMBER_VERTICES                             (NUMBER_TRIANGLES * 3)

#if 0 // TODO: DELETE THIS SECTION
// For texture - begin. ref.:http://www.raywenderlich.com/4404/opengl-es-2-0-for-iphone-tutorial-
// Add texture coordinates to Vertex structure as follows
struct Vertex{
    float Position[3];
    float Color[4];
    float TexCoord[2]; // New
};

// Add texture coordinates to Vertices as follows
const struct Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, 0}, {1, 0, 0, 1}, {1, 1}},
    {{-1, 1, 0}, {0, 1, 0, 1}, {0, 1}},
    {{-1, -1, 0}, {0, 1, 0, 1}, {0, 0}},
    {{1, -1, -1}, {1, 0, 0, 1}, {1, 0}},
    {{1, 1, -1}, {1, 0, 0, 1}, {1, 1}},
    {{-1, 1, -1}, {0, 1, 0, 1}, {0, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}, {0, 0}}
};

// For texture - end
#endif

@interface GameViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
//    GLKMatrix3 _normalMatrix;
    float _rotationCube;
    float _rotationViewer;
    float _rotationNormal;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    
    // For texture - begin
    GLuint _floorTexture;
    GLuint _fishTexture;
    GLuint _texCoordSlot;
    GLuint _textureUniform;
    GLuint _positionSlot;
    GLuint _colorSlot;

    // For texture - end
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

#if !_____ALWAYS_PUT_TO_false_BECAUSE_BROKEN_____USE_TEXTUR

- (void)setupGL_Generated;
- (void)tearDownGL;
- (void)setupCMMotion;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

// TO DELETE
//- (void) initializeGeometryAndTexture;

#else

#if 0 // TODO: DELETE THIS SECTION
{
// For texture - begin
- (GLuint)setupTexture:(NSString *)fileName;
- (GLuint)compileShaderTexture:(NSString*)shaderName withType:(GLenum)shaderType;
- (void)compileShadersTexture;
}
#endif

#endif

// For texture - end

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad called");
    NSLog(@"constant NUMBER_TRIANGLES_IN_WORLD : %d\n", NUMBER_TRIANGLES_IN_WORLD);
    NSLog(@"constant NUMBER_VERTICES_IN_WORLD  : %d\n", NUMBER_VERTICES_IN_WORLD);
    NSLog(@"constant NUMBER_FLOAT_PER_VERTEX   : %d\n", NUMBER_FLOAT_PER_VERTEX);
    NSLog(@"constant NUMBER_FLOAT_PER_TRIANGLE : %d\n", NUMBER_FLOAT_PER_TRIANGLE);
    NSLog(@"constant NUMBER_FLOATS_IN_WORLD    : %d\n", NUMBER_FLOATS_IN_WORLD);
    NSLog(@"constant OFFSET_IN_BYTES_TO_ACCESS_VERTEX_POS  : %d\n", OFFSET_IN_BYTES_TO_ACCESS_VERTEX_POS);
    NSLog(@"constant OFFSET_IN_BYTES_TO_ACCESS_VERTEX_NORM : %d\n", OFFSET_IN_BYTES_TO_ACCESS_VERTEX_NORM);
    NSLog(@"constant OFFSET_IN_BYTES_TO_ACCESS_VERTEX_UV   : %d\n", OFFSET_IN_BYTES_TO_ACCESS_VERTEX_UV);
    NSLog(@"sizeof(XYZ_t)              : %d\n", sizeof(XYZ_t));
    NSLog(@"sizeof(vertexFullInfo_t)   : %d\n", sizeof(vertexFullInfo_t));
    NSLog(@"sizeof(triangleFullInfo_t) : %d\n", sizeof(triangleFullInfo_t));
    
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL_Generated];
 //   _floorTexture = [self setupTexture:@"tile_floor.png"];
    [self setupCMMotion];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#if !_____ALWAYS_PUT_TO_false_BECAUSE_BROKEN_____USE_TEXTURE___
- (void)setupGL_Generated
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    // TO DELETE    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_allWorldInfo), g_allWorldInfo, GL_STATIC_DRAW);
    
#if ADD_CHECKERBOARD_TEXTURE
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // TO DELETE  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 4 /*bytes/float*/ * (3+3+2) /*xyzxyzUV*/, BUFFER_OFFSET(0));
    glVertexAttribPointer(GLKVertexAttribPosition, NUMBER_FLOAT_PER_POS, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * NUMBER_FLOAT_PER_VERTEX /*xyzxyzUV*/, BUFFER_OFFSET(OFFSET_IN_BYTES_TO_ACCESS_VERTEX_POS));
    // NORMALS ARE NOT USED IN THIS TEST VERSION -  glEnableVertexAttribArray(GLKVertexAttribNormal);
    // NORMALS ARE NOT USED IN THIS TEST VERSION -  glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 4 /*bytes/float*/ * (3+3+2) /*xyzxyzUV*/, BUFFER_OFFSET(4 /*bytes/float*/ * (3) /*after xyz*/));
    
    // MOVED LOWER IN CODE    glBindVertexArrayOES(0);
    
    

    // based on https://open.gl/textures
    GLuint mytex;
    glGenTextures(ATTRIB_TEXTURE, &mytex);
    glBindTexture(GL_TEXTURE_2D, mytex);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    
    
    // COULD ALSO WORK -        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // COULD ALSO WORK -        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    // COULD ALSO WORK -        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    
    // COULD ALSO WORK -        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    // Black/white checkerboard
//    float pixels[] = {
//        1.0f, 0.0f, 0.0f,   1.0f, 1.0f, 0.0f,
//        1.0f, 1.0f, 1.0f,   0.0f, 0.0f, 1.0f
//    };
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 2, 2, 0, GL_RGB, GL_FLOAT, pixels);

    
    
//    float pixels4x4[] = {
//        0.2f, 0.2f, 0.0f,   0.2f, 0.4f, 0.0f,   0.2f, 0.6f, 0.0f,   0.2f, 0.6f, 0.0f,
//        0.4f, 0.2f, 1.0f,   0.4f, 0.4f, 0.0f,   0.4f, 0.6f, 0.0f,   0.4f, 0.6f, 0.0f,
//        0.6f, 0.2f, 0.0f,   0.6f, 0.4f, 0.0f,   0.6f, 0.6f, 0.0f,   0.6f, 0.6f, 0.0f,
//        0.8f, 0.2f, 0.0f,   0.8f, 0.4f, 0.0f,   0.8f, 0.6f, 0.0f,   0.8f, 0.6f, 0.0f
//    };
//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 4, 4, 0, GL_RGB, GL_FLOAT, pixels4x4);

    
    
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, Brudslojan_skybox_image_416x312_3_BytesPerPixel.width, Brudslojan_skybox_image_416x312_3_BytesPerPixel.height, 0, GL_RGB, GL_UNSIGNED_BYTE, Brudslojan_skybox_image_416x312_3_BytesPerPixel.pixel_data);

    
    // This line was defective. Replaced by next one -  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glEnableVertexAttribArray(ATTRIB_TEXTURE);

    // This line was defective. Replaced by next one -  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 4 /*bytes/float*/ * (3+3+2) /*xyzxyzUV*/, BUFFER_OFFSET(4 /*bytes/float*/ * (3+3) /*after xyzxyz*/));
    // TO DELETE glVertexAttribPointer(ATTRIB_TEXTURE, 2, GL_FLOAT, GL_FALSE, 4 /*bytes/float*/ * (3+3+2) /*xyzxyzUV*/, BUFFER_OFFSET(4 /*bytes/float*/ * (3+3) /*after xyzxyz*/));
    glVertexAttribPointer(ATTRIB_TEXTURE, NUMBER_FLOAT_PER_UV, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * NUMBER_FLOAT_PER_VERTEX /*xyzxyzUV*/, BUFFER_OFFSET(OFFSET_IN_BYTES_TO_ACCESS_VERTEX_UV /*after xyzxyz*/));

    // This line was defective. Replaced by next one -  glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "texCoordIn");
    glBindAttribLocation(_program, ATTRIB_TEXTURE, "texCoordIn");
    
    glBindAttribLocation(_program, ATTRIB_OBJECT_NUMBER, "objectNumber");
    
#endif
    

}
#else
- (void)setupGL_Texture
{
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);

    glEnable(GL_DEPTH_TEST);

}
// For texture - begin
- (GLuint)setupTexture:(NSString *)fileName {
    // 1
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    // 4
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);        
    return texName;    
}

- (GLuint)compileShaderTexture:(NSString*)shaderName withType:(GLenum)shaderType {
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

- (void)compileShadersTexture {
    
    // 1
    GLuint vertexShader = [self compileShaderTexture:@"SimpleVertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderTexture:@"SimpleFragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    // 2
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
}
// For texture - end

#endif

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}


///////////////////// Test Sbinet for motion
- (void)setupCMMotion
{
    MyCMMotionManager = [[CMMotionManager alloc] init];
    
    [MyCMMotionManager startDeviceMotionUpdates];

}
///////////////////// Test Sbinet for motion - end



#pragma mark - GLKView and GLKViewController delegate methods

#if !_____ALWAYS_PUT_TO_false_BECAUSE_BROKEN_____USE_TEXTURE___
- (void)update
{
    if (0) { // put 1 make rotations
        //    _rotationCube = 0.45;
        //    _rotationViewer = 0;
        //    _rotationNormal = 0;
    }
    
    
    
    
    
    ///////////////////// Test Sbinet for motion
    CMAttitude *myAtt = MyCMMotionManager.deviceMotion.attitude;
    CMRotationMatrix r = myAtt.rotationMatrix;
    // test 1 - pas les bons axes
//    GLKMatrix4 motionMatrix = GLKMatrix4Make(r.m11, r.m21, r.m31, 0.0f,
//                                             r.m12, r.m22, r.m32, 0.0f,
//                                             r.m13, r.m23, r.m33, 0.0f,
//                                             0.0f,  0.0f,  -4.0f, 1.0f);
    // test 2 -
    // convert CMRotationMatrix to GLKMatrix4
    GLKMatrix4 motionMatrix = GLKMatrix4Make(r.m11, r.m21, r.m31, 0.0f,
                                r.m12, r.m22, r.m32, 0.0f,
                                r.m13, r.m23, r.m33, 0.0f,
                                0.0f,  0.0f,  0.0f, 1.0f);
    motionMatrix = GLKMatrix4RotateX(motionMatrix, M_PI / 2);
    
    /////////////// test sbinet - end


    
    /////////////// projection
    GLKMatrix4 modelViewMatrix;
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    // original code for red cube in GLKit    self.effect.transform.projectionMatrix = projectionMatrix;
    /////////////// projection - end
    
    
    /////////////// Viewer matrix
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    int yyyyy=1;
    if(yyyyy) { // 1 means use orientation of iOS device
        /////////////// use device orientation
        baseModelViewMatrix = GLKMatrix4Multiply(motionMatrix, baseModelViewMatrix);
        /////////////// use device orientation - end
    } else {
        /////////////// original rotation
        baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotationViewer, 0.2f, 1.0f, 0.0f);
        /////////////// original rotation - end
    }
    /////////////// Viewer matrix - end
    
    
    /////////////// Object Move is world space matrix
//     Compute the model view matrix for the object rendered with GLKit
//    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotationCube, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    if (SHOULD_MOVE_ALL_OBJECTS_AROUND_FIXED_POINT) {
        modelViewMatrix = GLKMatrix4MakeTranslation(OBJECTS_CENTER_COORD);
    }
    else {
        modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    }

    if (SHOULD_TURN_ALL_OBJECTS_AROUND_FIXED_POINT) {
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotationCube, 0.0f, 1.0f, 0.0f);
    }
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    /////////////// Object Move is world space matrix - end
    

if (0) {
    /////////////// test for normals
    GLKMatrix4 modelViewMatrixForNormal = GLKMatrix4MakeTranslation(0.0f, 0.0f, -2.0f);
    modelViewMatrixForNormal = GLKMatrix4Rotate(modelViewMatrixForNormal, _rotationNormal, 0.0f, 1.0f, 0.0f);
    modelViewMatrixForNormal = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrixForNormal);
    // test only GLKMatrix4 modelViewMatrixIdentityTest = GLKMatrix4MakeTranslation(0.0f, 1.0f, 0.0f);
//    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrixForNormal), NULL);
    /////////////// test for normals - end
} else {
    /////////////// original normals
//    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    /////////////// original normals - end
}
    

    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotationCube += self.timeSinceLastUpdate * 0.5f;
//    _rotationViewer += self.timeSinceLastUpdate * 0.5f;
//    _rotationNormal += self.timeSinceLastUpdate * 0.5f;
}

#else
- (void)update
{
}
#endif

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, NUMBER_VERTICES_IN_WORLD);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
//    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    // if ever we need a value sweeping between 0 and 1, use sebFloatUniform
    GLfloat varValue = ((int)(_rotationCube * 100) % 100 ) / 100.0f;
    GLint sebasUniformLoc = glGetUniformLocation(_program, "sebFloatUniform");
    glUniform1f(sebasUniformLoc, varValue);
    glDrawArrays(GL_TRIANGLES, 0, NUMBER_VERTICES_IN_WORLD);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    // original before texture    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
//    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
//    // For texture
//    GLint samplerLoc = glGetUniformLocation(_program, "mytexture");
//    // Indicate that the diffuse texture will be bound to texture unit 0
//    GLint unit = 2;
//    //glUniform1i(samplerLoc, unit);
    
    
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

// TO DELETE
//- (void) initializeGeometryAndTexture
//
//{
//    pos_SKYBOX = (float*)malloc(NUMBER_FLOATS_IN_WORLD);
//
//    const XYZ_t verticesInfoUnitBox[] = {
//        //                  x,       y,       z
//        /*vertex [ 1]*/   { 0.5f,   -0.5f,    0.5f},
//        /*vertex [ 2]*/   { 0.5f,    0.5f,    0.5f},
//        /*vertex [ 3]*/   {-0.5f,    0.5f,    0.5f},
//        /*vertex [ 4]*/   {-0.5f,   -0.5f,    0.5f},
//        /*vertex [ 5]*/   { 0.5f,   -0.5f,    0.5f},
//        /*vertex [ 6]*/   { 0.5f,   -0.5f,   -0.5f},
//        /*vertex [ 7]*/   { 0.5f,    0.5f,   -0.5f},
//        /*vertex [ 8]*/   {-0.5f,    0.5f,   -0.5f},
//        /*vertex [ 9]*/   {-0.5f,   -0.5f,   -0.5f},
//        /*vertex [10]*/   { 0.5f,   -0.5f,   -0.5f},
//        /*vertex [11]*/   { 0.5f,   -0.5f,    0.5f},
//        /*vertex [12]*/   {-0.5f,   -0.5f,    0.5f},
//        /*vertex [13]*/   { 0.5f,   -0.5f,   -0.5f},
//        /*vertex [14]*/   {-0.5f,   -0.5f,   -0.5f}
//    };
//    
//    const XYZ_t pos_SKYBOX_local[] = {
//        /*vertex [ 1]*/   { SKY_BOX_SCALE  *  SKY_BOX_SCALE,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 1].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 1].z},
//        /*vertex [ 2]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 2].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 2].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 2].z},
//        /*vertex [ 3]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 3].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 3].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 3].z},
//        /*vertex [ 4]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 4].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 4].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 4].z},
//        /*vertex [ 5]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 5].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 5].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 5].z},
//        /*vertex [ 6]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 6].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 6].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 6].z},
//        /*vertex [ 7]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 7].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 7].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 7].z},
//        /*vertex [ 8]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 8].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 8].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 8].z},
//        /*vertex [ 9]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[ 9].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[ 9].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[ 9].z},
//        /*vertex [10]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[10].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[10].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[10].z},
//        /*vertex [11]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[11].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[11].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[11].z},
//        /*vertex [12]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[12].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[12].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[12].z},
//        /*vertex [13]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[13].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[13].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[13].z},
//        /*vertex [14]*/   { SKY_BOX_SCALE  *  verticesInfoUnitBox[14].x,   SKY_BOX_SCALE  *  verticesInfoUnitBox[14].y,    SKY_BOX_SCALE  *  verticesInfoUnitBox[14].z}
//    };
//
//}


@end

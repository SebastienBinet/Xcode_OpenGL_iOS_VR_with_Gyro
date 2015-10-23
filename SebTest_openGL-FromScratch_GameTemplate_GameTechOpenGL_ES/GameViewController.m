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


#define OBJECTS_CENTER_COORD                        3.0f, -1.0f, 0.0f
#define SHOULD_TURN_ALL_OBJECTS_AROUND_FIXED_POINT  true
#define SHOULD_MOVE_ALL_OBJECTS_AROUND_FIXED_POINT  true



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


#define NUMBER_VERTICES_PER_TRIANGLE  3
#define NUMBER_TRIANGLE_PER_SQUARE    2

#define NUMBER_TRIANGLES_IN_UNROLLED_SKYBOX_A     ( NUMBER_TRIANGLE_PER_SQUARE )
#define NUMBER_VERTICES_IN_UNROLLED_SKYBOX_A      ( NUMBER_VERTICES_PER_TRIANGLE * NUMBER_TRIANGLES_IN_UNROLLED_SKYBOX_A)

#define NUMBER_TRIANGLES_IN_SKYBOX_A              ( 6 * NUMBER_TRIANGLE_PER_SQUARE )
#define NUMBER_VERTICES_IN_SKYBOX_A               ( NUMBER_VERTICES_PER_TRIANGLE * NUMBER_TRIANGLES_IN_SKYBOX_A)


#define NUMBER_TRIANGLES_IN_CUBE_B                ( 6 * NUMBER_TRIANGLE_PER_SQUARE )
#define NUMBER_VERTICES_IN_CUBE_B                 ( NUMBER_VERTICES_PER_TRIANGLE * NUMBER_TRIANGLES_IN_CUBE_B)


//#define NUMBER_TRIANGLES_IN_WORLD     (                                                  \
//                                        (   1 /*  1 square  to show the unrolled skybox*/  \
//                                          + 6 /*  6 squares of skybox */                 \
//                                          + 6 /*  6 squares of a cube */                 \
//                                        )                                                \
//                                        * NUMBER_TRIANGLE_PER_SQUARE                     \
//                                      )




#define NUMBER_FLOAT_PER_POS          3 // PosX, PosY, PosZ
#define NUMBER_FLOAT_PER_NORMAL       3 // NormX, NormY, NormZ
#define NUMBER_FLOAT_PER_UV           2 // U, V

#define NUMBER_FLOAT_PER_VERTEX       ( NUMBER_FLOAT_PER_POS  +  NUMBER_FLOAT_PER_NORMAL  +  NUMBER_FLOAT_PER_UV )

#define NUMBER_FLOAT_PER_TRIANGLE  ( NUMBER_VERTICES_PER_TRIANGLE  *  NUMBER_FLOAT_PER_VERTEX )


#define UV_IN_TEXTURE_A_FOR_VERTEX__1 0.00, 0.34
#define UV_IN_TEXTURE_A_FOR_VERTEX__2 0.26, 0.34
#define UV_IN_TEXTURE_A_FOR_VERTEX__3 0.49, 0.34
#define UV_IN_TEXTURE_A_FOR_VERTEX__4 0.75, 0.34
#define UV_IN_TEXTURE_A_FOR_VERTEX__5 1.00, 0.34
#define UV_IN_TEXTURE_A_FOR_VERTEX__6 0.00, 0.66
#define UV_IN_TEXTURE_A_FOR_VERTEX__7 0.26, 0.66
#define UV_IN_TEXTURE_A_FOR_VERTEX__8 0.49, 0.66
#define UV_IN_TEXTURE_A_FOR_VERTEX__9 0.75, 0.66
#define UV_IN_TEXTURE_A_FOR_VERTEX_10 1.00, 0.66
#define UV_IN_TEXTURE_A_FOR_VERTEX_11 0.26, 0.00
#define UV_IN_TEXTURE_A_FOR_VERTEX_12 0.49, 0.00
#define UV_IN_TEXTURE_A_FOR_VERTEX_13 0.26, 1.00
#define UV_IN_TEXTURE_A_FOR_VERTEX_14 0.49, 1.00

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


triangleFullInfo_t g_UnrolledSkybox_A__Info[ NUMBER_TRIANGLES_IN_UNROLLED_SKYBOX_A ] =
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
    }
};

triangleFullInfo_t g_Skybox_A__Info[ NUMBER_TRIANGLES_IN_SKYBOX_A ] =
{
    

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
    //   <- -z    +x     +z ->      and -x is back of you.
    //
    //            +y
    //             |
    //             v
    
    // x
    {
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 1.0f, -1.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__7} },
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 1.0f,  1.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__2} },
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__8} }
    },
    {
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__8} },
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 1.0f,  1.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__2} },
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 1.0f,  1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__3} }
    },
    
    // y
    {
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__2} },
    /*11*/      { {-5.0f,      5.0f,         -5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_11} },
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__3} }
    },
    {
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__3} },
    /*11*/      { {-5.0f,      5.0f,         -5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_11} },
    /*12*/      { {-5.0f,      5.0f,          5.0f},       { 0.0f,  1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_12} }
    },
    
    // -x
    {
    /* 5*/      { {-5.0f,      5.0f,         -5.0f},       {-1.0f,  1.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__5} },
    /*10*/      { {-5.0f,     -5.0f,         -5.0f},       {-1.0f, -1.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_10} },
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__4} }
    },
    {
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__4} },
    /*10*/      { {-5.0f,     -5.0f,         -5.0f},       {-1.0f, -1.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_10} },
    /* 9*/      { {-5.0f,     -5.0f,          5.0f},       {-1.0f, -1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__9} }
    },
    
    // -y
    {
    /*13*/      { {-5.0f,     -5.0f,         -5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_13} },
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__7} },
    /*14*/      { {-5.0f,     -5.0f,          5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_14} }
    },
    {
    /*14*/      { {-5.0f,     -5.0f,          5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX_14} },
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__7} },
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 0.0f, -1.0f,  0.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__8} }
    },

    // z
    {
    /* 3*/      { { 5.0f,      5.0f,          5.0f},       { 1.0f,  1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__3} },
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__4} },
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__8} }
    },
    {
    /* 8*/      { { 5.0f,     -5.0f,          5.0f},       { 1.0f, -1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__8} },
    /* 4*/      { {-5.0f,      5.0f,          5.0f},       {-1.0f,  1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__4} },
    /* 9*/      { {-5.0f,     -5.0f,          5.0f},       {-1.0f, -1.0f,  1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__9} }
    },
    
    // -z
    {
    /* 7*/      { { 5.0f,     -5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__7} },
    /* 6*/      { {-5.0f,     -5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__6} },
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__2} }
    },
    {
    /* 2*/      { { 5.0f,      5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__2} },
    /* 6*/      { {-5.0f,     -5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__6} },
    /* 1*/      { {-5.0f,      5.0f,         -5.0f},       { 0.0f,  0.0f, -1.0f},      { UV_IN_TEXTURE_A_FOR_VERTEX__1} }
    }
};

//
//    
//    //
//    // SMALL CUBE
//    //
//    
//    // x
//    /* 6*/  0.5f - 1, -0.5f - 1,        -5.0f,        1.0f, -1.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__6,
//    /* 7*/  0.5f - 1,  0.5f - 1,        -5.0f,        1.0f,  1.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__7,
//    /* 1*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__1,
//    /* 1*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__1,
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        1.0f,  1.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__7,
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        1.0f,  1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__2,
//    
//    // y
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__7,
//    /* 8*/ -0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__8,
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__2,
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__2,
//    /* 8*/ -0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__8,
//    /* 3*/ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        0.0f,  1.0f,  0.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__3,
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
//    /* 2*/  0.5f - 1,  0.5f - 1,  0.5f + 4.0f,        1.0f,  1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__2,
//    /* 3*/ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,       -1.0f,  1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__3,
//    /*11*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX_11,
//    /*11*/  0.5f - 1, -0.5f - 1,  0.5f + 4.0f,        1.0f, -1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX_11,
//    /* 3*/ -0.5f - 1,  0.5f - 1,  0.5f + 4.0f,       -1.0f,  1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__3,
//    /*12*/ -0.5f - 1, -0.5f - 1,  0.5f + 4.0f,       -1.0f, -1.0f,  1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX_12,
//    
//    // -z
//    /*13*/  0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX_13,
//    /*14*/ -0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX_14,
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__7,
//    /* 7*/  0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__7,
//    /*14*/ -0.5f - 1, -0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX_14,
//    /* 8*/ -0.5f - 1,  0.5f - 1, -0.5f + 4.0f,        0.0f,  0.0f, -1.0f,      UV_IN_TEXTURE_A_FOR_VERTEX__8
//


@interface GameViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix_ForUnrolledSkybox_A;
    GLKMatrix4 _modelViewProjectionMatrix_ForSkybox_A;
    float _rotationCube;
    float _rotationNormal;
    
    GLuint _vertexArray_UnrolledSkybox_A;
    GLuint _vertexArray_Skybox_A;
    GLuint _vertexBuffer_UnrolledSkybox_A;
    GLuint _vertexBuffer_Skybox_A;
    
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;


- (void)setupGL;
- (void)tearDownGL;
- (void)setupCMMotion;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
- (void)prepareForDrawing_UnrolledSkybox_A;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad called");
//    NSLog(@"constant NUMBER_TRIANGLES_IN_WORLD : %d\n", NUMBER_TRIANGLES_IN_WORLD);
//    NSLog(@"constant NUMBER_VERTICES_IN_WORLD  : %d\n", NUMBER_VERTICES_IN_WORLD);
    NSLog(@"constant NUMBER_FLOAT_PER_VERTEX   : %d\n", NUMBER_FLOAT_PER_VERTEX);
    NSLog(@"constant NUMBER_FLOAT_PER_TRIANGLE : %d\n", NUMBER_FLOAT_PER_TRIANGLE);
//    NSLog(@"constant NUMBER_FLOATS_IN_WORLD    : %d\n", NUMBER_FLOATS_IN_WORLD);
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
    
    [self setupGL];
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


- (void) prepareForDrawing_UnrolledSkybox_A
{
    glBindVertexArrayOES(_vertexArray_UnrolledSkybox_A);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer_UnrolledSkybox_A);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_UnrolledSkybox_A__Info), g_UnrolledSkybox_A__Info, GL_STATIC_DRAW);

    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, NUMBER_FLOAT_PER_POS, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * NUMBER_FLOAT_PER_VERTEX /*xyzxyzUV*/, BUFFER_OFFSET(OFFSET_IN_BYTES_TO_ACCESS_VERTEX_POS));
    
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    glVertexAttribPointer(ATTRIB_TEXTURE, NUMBER_FLOAT_PER_UV, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * NUMBER_FLOAT_PER_VERTEX /*xyzxyzUV*/, BUFFER_OFFSET(OFFSET_IN_BYTES_TO_ACCESS_VERTEX_UV /*after xyzxyz*/));
}


- (void) prepareForDrawing_Skybox_A
{
    glBindVertexArrayOES(_vertexArray_Skybox_A);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer_Skybox_A);
    glBufferData(GL_ARRAY_BUFFER, sizeof(g_Skybox_A__Info), g_Skybox_A__Info, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, NUMBER_FLOAT_PER_POS, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * NUMBER_FLOAT_PER_VERTEX /*xyzxyzUV*/, BUFFER_OFFSET(OFFSET_IN_BYTES_TO_ACCESS_VERTEX_POS));
    
    glEnableVertexAttribArray(ATTRIB_TEXTURE);
    glVertexAttribPointer(ATTRIB_TEXTURE, NUMBER_FLOAT_PER_UV, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * NUMBER_FLOAT_PER_VERTEX /*xyzxyzUV*/, BUFFER_OFFSET(OFFSET_IN_BYTES_TO_ACCESS_VERTEX_UV /*after xyzxyz*/));
}


- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray_UnrolledSkybox_A);
    glGenVertexArraysOES(1, &_vertexArray_Skybox_A);
    
    glGenBuffers(1, &_vertexBuffer_UnrolledSkybox_A);
    glGenBuffers(1, &_vertexBuffer_Skybox_A);

    
    

    // NORMALS ARE NOT USED IN THIS TEST VERSION -  glEnableVertexAttribArray(GLKVertexAttribNormal);
    // NORMALS ARE NOT USED IN THIS TEST VERSION -  glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 4 /*bytes/float*/ * (3+3+2) /*xyzxyzUV*/, BUFFER_OFFSET(4 /*bytes/float*/ * (3) /*after xyz*/));
    

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

    
    // This line was defective. Replaced by next one -  glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "texCoordIn");
    glBindAttribLocation(_program, ATTRIB_TEXTURE, "texCoordIn");
    
    glBindAttribLocation(_program, ATTRIB_OBJECT_NUMBER, "objectNumber");
    
    

}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer_UnrolledSkybox_A);
    glDeleteVertexArraysOES(1, &_vertexArray_UnrolledSkybox_A);
    glDeleteBuffers(1, &_vertexBuffer_Skybox_A);
    glDeleteVertexArraysOES(1, &_vertexArray_Skybox_A);
    
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

- (void)update
{
    
    ///////////////////// Test Sbinet for motion
    CMAttitude *myAtt = MyCMMotionManager.deviceMotion.attitude;
    CMRotationMatrix r = myAtt.rotationMatrix;

    // convert CMRotationMatrix to GLKMatrix4
    GLKMatrix4 motionMatrix = GLKMatrix4Make(r.m11, r.m21, r.m31, 0.0f,
                                r.m12, r.m22, r.m32, 0.0f,
                                r.m13, r.m23, r.m33, 0.0f,
                                0.0f,  0.0f,  0.0f, 1.0f);
    motionMatrix = GLKMatrix4RotateX(motionMatrix, M_PI / 2);
    
    /////////////// test sbinet - end


    
    /////////////// projection
    GLKMatrix4 modelViewMatrix_ForUnrolledSybox_A;
    GLKMatrix4 modelViewMatrix_ForSkybox_A;
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    // original code for red cube in GLKit    self.effect.transform.projectionMatrix = projectionMatrix;
    /////////////// projection - end
    
    
    /////////////// Viewer matrix
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    /////////////// use device orientation
    baseModelViewMatrix = GLKMatrix4Multiply(motionMatrix, baseModelViewMatrix);
    /////////////// Viewer matrix - end
    
    
    /////////////// Object Move is world space matrix
//     Compute the model view matrix for the object rendered with GLKit
//    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotationCube, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    self.effect.transform.modelviewMatrix = modelViewMatrix_ForUnrolledSybox_A;
    
    // Compute the model view matrix for objects rendered with ES2
    modelViewMatrix_ForSkybox_A = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    if (SHOULD_MOVE_ALL_OBJECTS_AROUND_FIXED_POINT) {
        modelViewMatrix_ForUnrolledSybox_A = GLKMatrix4MakeTranslation(OBJECTS_CENTER_COORD);
    }
    else {
        modelViewMatrix_ForUnrolledSybox_A = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    }

    if (SHOULD_TURN_ALL_OBJECTS_AROUND_FIXED_POINT) {
        modelViewMatrix_ForUnrolledSybox_A = GLKMatrix4Rotate(modelViewMatrix_ForUnrolledSybox_A, _rotationCube, 0.0f, 1.0f, 0.0f);
    }
    modelViewMatrix_ForUnrolledSybox_A = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix_ForUnrolledSybox_A);
    modelViewMatrix_ForSkybox_A = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix_ForSkybox_A);
    /////////////// Object Move is world space matrix - end
    

//if (0) {
//    /////////////// test for normals
//    GLKMatrix4 modelViewMatrixForNormal = GLKMatrix4MakeTranslation(0.0f, 0.0f, -2.0f);
//    modelViewMatrixForNormal = GLKMatrix4Rotate(modelViewMatrixForNormal, _rotationNormal, 0.0f, 1.0f, 0.0f);
//    modelViewMatrixForNormal = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrixForNormal);
//    // test only GLKMatrix4 modelViewMatrixIdentityTest = GLKMatrix4MakeTranslation(0.0f, 1.0f, 0.0f);
////    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrixForNormal), NULL);
//    /////////////// test for normals - end
//} else {
//    /////////////// original normals
////    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
//    /////////////// original normals - end
//}
    

    
    _modelViewProjectionMatrix_ForUnrolledSkybox_A = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix_ForUnrolledSybox_A);
    _modelViewProjectionMatrix_ForSkybox_A = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix_ForSkybox_A);
    
    _rotationCube += self.timeSinceLastUpdate * 0.5f;
//    _rotationNormal += self.timeSinceLastUpdate * 0.5f;
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    
    
    
    //
    // UnrolledSkybox_A
    //
    
//  moved in function      glBindVertexArrayOES(_vertexArray);
    [self prepareForDrawing_UnrolledSkybox_A];
    
    // Render the object with GLKit
    //    [self.effect prepareToDraw];
    //    glDrawArrays(GL_TRIANGLES, 0, NUMBER_VERTICES_IN_UNROLLED_SKYBOX_A);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix_ForUnrolledSkybox_A.m);
    //    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    // if ever we need a value sweeping between 0 and 1, use sebFloatUniform
    GLfloat varValue = ((int)(_rotationCube * 100) % 100 ) / 100.0f;
    GLint sebasUniformLoc = glGetUniformLocation(_program, "sebFloatUniform");
    glUniform1f(sebasUniformLoc, varValue);
    
    glDrawArrays(GL_TRIANGLES, 0, NUMBER_VERTICES_IN_UNROLLED_SKYBOX_A);
    
    
    
    
    
    //
    // Skybox_A
    //
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix_ForSkybox_A.m);

    [self prepareForDrawing_Skybox_A];
    glDrawArrays(GL_TRIANGLES, 0, NUMBER_VERTICES_IN_SKYBOX_A);

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
    // original with normals before texture    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    
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



@end

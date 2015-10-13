//
//  GameViewController.m
//  to_delete
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

#define OBJECTS_CENTER_COORD                        0.0f, -1.0f, 4.0f
#define SHOULD_TURN_ALL_OBJECTS_AROUND_FIXED_POINT  true
#define SHOULD_MOVE_ALL_OBJECTS_AROUND_FIXED_POINT  false
#define USE_SKY_BOX_INSTEAD_OF_2_SMALL_CUBES        true




#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

#if USE_SKY_BOX_INSTEAD_OF_2_SMALL_CUBES
#define NUMBER_SQUARE                               1 + 12
#define NUMBER_FLOAT                                (NUMBER_SQUARE * 36)

GLfloat gCubeVertexData[NUMBER_FLOAT] =
{
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,

    // 1/6 of skybox
    -0.5f, -0.5f, -0.5f,        1.0f, -1.0f, -1.0f,
    -0.5f, 0.5f, -0.5f,         1.0f, 1.0f, -1.0f,
    -0.5f, -0.5f, 0.5f,         1.0f, -1.0f, 1.0f
    ,
    -0.5f, -0.5f, 0.5f,         1.0f, -1.0f, 1.0f,
    -0.5f, 0.5f, -0.5f,         1.0f, 1.0f, -1.0f,
    -0.5f, 0.5f, 0.5f,          1.0f, 1.0f, 1.0f
    ,
    
    
    
    
    // small cube
    0.5f -1, -0.5f - 1, -0.5f + 4.0f,        1.0f, -1.0f, -1.0f,
    0.5f -1, 0.5f - 1, -0.5f + 4.0f,         1.0f, 1.0f, -1.0f,
    0.5f -1, -0.5f - 1, 0.5f + 4.0f,         1.0f, -1.0f, 1.0f
    ,
    0.5f -1, -0.5f - 1, 0.5f + 4.0f,         1.0f, -1.0f, 1.0f,
    0.5f -1, 0.5f - 1, -0.5f + 4.0f,         1.0f, 1.0f, -1.0f,
    0.5f -1, 0.5f - 1, 0.5f + 4.0f,          1.0f, 1.0f, 1.0f
    ,
    
    0.5f -1, 0.5f - 1, -0.5f + 4.0f,         0.0f, 1.0f, 0.0f,
    -0.5f -1, 0.5f - 1, -0.5f + 4.0f,        0.0f, 1.0f, 0.0f,
    0.5f -1, 0.5f - 1, 0.5f + 4.0f,          0.0f, 1.0f, 0.0f,
    0.5f -1, 0.5f - 1, 0.5f + 4.0f,          0.0f, 1.0f, 0.0f,
    -0.5f -1, 0.5f - 1, -0.5f + 4.0f,        0.0f, 1.0f, 0.0f,
    -0.5f -1, 0.5f - 1, 0.5f + 4.0f,         0.0f, 1.0f, 0.0f
    ,
    
    -0.5f -1, 0.5f - 1, -0.5f + 4.0f,     -1.0f, 1.0f, -1.0f,
    -0.5f -1, -0.5f - 1, -0.5f + 4.0f,    -1.0f, -1.0f, -1.0f,
    -0.5f -1, 0.5f - 1, 0.5f + 4.0f,      -1.0f, 1.0f, 1.0f,
    -0.5f -1, 0.5f - 1, 0.5f + 4.0f,      -1.0f, 1.0f, 1.0f,
    -0.5f -1, -0.5f - 1, -0.5f + 4.0f,    -1.0f, -1.0f, -1.0f,
    -0.5f -1, -0.5f - 1, 0.5f + 4.0f,     -1.0f, -1.0f, 1.0f
    ,
    
    -0.5f -1, -0.5f - 1, -0.5f + 4.0f,    0.0f, -1.0f, 0.0f,
    0.5f -1, -0.5f - 1, -0.5f + 4.0f,     0.0f, -1.0f, 0.0f,
    -0.5f -1, -0.5f - 1, 0.5f + 4.0f,     0.0f, -1.0f, 0.0f,
    -0.5f -1, -0.5f - 1, 0.5f + 4.0f,     0.0f, -1.0f, 0.0f,
    0.5f -1, -0.5f - 1, -0.5f + 4.0f,     0.0f, -1.0f, 0.0f,
    0.5f -1, -0.5f - 1, 0.5f + 4.0f,      0.0f, -1.0f, 0.0f
    ,
    
    0.5f -1, 0.5f - 1, 0.5f + 4.0f,       1.0f, 1.0f, 1.0f,
    -0.5f -1, 0.5f - 1, 0.5f + 4.0f,      -1.0f, 1.0f, 1.0f,
    0.5f -1, -0.5f - 1, 0.5f + 4.0f,      1.0f, -1.0f, 1.0f
    ,
    0.5f -1, -0.5f - 1, 0.5f + 4.0f,      1.0f, -1.0f, 1.0f,
    -0.5f -1, 0.5f - 1, 0.5f + 4.0f,      -1.0f, 1.0f, 1.0f,
    -0.5f -1, -0.5f - 1, 0.5f + 4.0f,     -1.0f, -1.0f, 1.0f
    ,
    
    0.5f -1, -0.5f - 1, -0.5f + 4.0f,     0.0f, 0.0f, -1.0f,
    -0.5f -1, -0.5f - 1, -0.5f + 4.0f,    0.0f, 0.0f, -1.0f,
    0.5f -1, 0.5f - 1, -0.5f + 4.0f,      0.0f, 0.0f, -1.0f
    ,
    0.5f -1, 0.5f - 1, -0.5f + 4.0f,      0.0f, 0.0f, -1.0f,
    -0.5f -1, -0.5f - 1, -0.5f + 4.0f,    0.0f, 0.0f, -1.0f,
    -0.5f -1, 0.5f - 1, -0.5f + 4.0f,     0.0f, 0.0f, -1.0f

};

#else

#define NUMBER_SQUARE                               12
#define NUMBER_FLOAT                                (NUMBER_SQUARE * 36)

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
#define NUMBER_TRIANGLE                             (NUMBER_SQUARE * 2)
#define NUMBER_VERTEX                               (NUMBER_TRIANGLE * 3)


@interface GameViewController () {
    GLuint _program;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotationCube;
    float _rotationViewer;
    float _rotationNormal;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
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
@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

- (void)setupGL
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
}

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
    if(1) { // 1 means use orientation of iOS device
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
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrixForNormal), NULL);
    /////////////// test for normals - end
} else {
    /////////////// original normals
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    /////////////// original normals - end
}
    

    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    _rotationCube += self.timeSinceLastUpdate * 0.5f;
    _rotationViewer += self.timeSinceLastUpdate * 0.5f;
    _rotationNormal += self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object with GLKit
    [self.effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLES, 0, NUMBER_VERTEX);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    
    glDrawArrays(GL_TRIANGLES, 0, NUMBER_VERTEX);
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
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
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
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
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

//
//  Shader.fsh
//  SebTest_openGL-FromScratch_GameTemplate_GameTechOpenGL_ES
//
//  Created by Sebastien Binet on 2015-10-08.
//  Copyright © 2015 Sebastien Binet. All rights reserved.
//

// original before texture    varying lowp vec4 colorVarying;

// for Texture
varying lowp vec2 texCoordOut;
uniform sampler2D mytexture;

void main()
{
    // original before texture    gl_FragColor = colorVarying;
    // for Texture
//    gl_FragColor = vec4(texCoordOut.x , texCoordOut.y, 0.0, 1.0);
    gl_FragColor = texture2D(mytexture, texCoordOut);
//    gl_FragColor = texture2D(mytexture, texCoordOut.st, 0.0);
//    gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0);

}

// CVSDMTemporaryResourceRemovalOption.h
// CVSDrawingModel
// Created by J on 10/26/13.
// Copyright (c) 2013 Canvas. All rights reserved.

/**
 @brief specifies a deletion option for a temporary directory
 */
typedef NS_ENUM(uint8_t, CVSDMTemporaryResourceRemovalOption) {
    /**
     @constant do not use
     */
    CVSDMTemporaryResourceRemovalOption_Undefined = 0,
    /**
     @constant remove the directory or delete the file (e.g. when the instance is deallocated)
     */
    CVSDMTemporaryResourceRemovalOption_Remove,
    /**
     @constant do not remove/delete the resource when the instance is deallocated
     */
    CVSDMTemporaryResourceRemovalOption_DoNotRemove
};


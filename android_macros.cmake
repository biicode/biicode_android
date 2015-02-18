function(BII_ADD_LIBRARY libname libsources)
    SET(BII_IMPLICIT_RULES_ENABLED OFF PARENT_SCOPE)
	add_library(${libname} ${libsources})
endfunction()

function(BII_ADD_EXECUTABLE exename exesources)
	SET(BII_IMPLICIT_RULES_ENABLED OFF PARENT_SCOPE)
	BII_GENERATE_ANDROID_APK(${USER} ${BLOCK} ${FNAME})
	SET(BII_${FNAME}_NAME ${vname} PARENT_SCOPE)
endfunction()



function(BII_GENERATE_ANDROID_APK USER BLOCK FNAME)
	SET(vname "${USER}_${BLOCK}_${FNAME}")
	SET(aux_src ${BII_${FNAME}_SRC})
	ADD_LIBRARY(${vname} SHARED ${aux_src})
	SET(interface_target "${BII_BLOCK_USER}_${BII_BLOCK_NAME}_interface")
    if(BII_${FNAME}_DEPS)
        TARGET_LINK_LIBRARIES( ${vname} PUBLIC ${BII_${FNAME}_DEPS})
    endif()
	if(BII_${FNAME}_INCLUDE_PATHS)
        target_include_directories( ${vname} PUBLIC ${BII_${FNAME}_INCLUDE_PATHS})
    endif()
    TARGET_LINK_LIBRARIES( ${vname} PUBLIC ${interface_target})
	SET(BII_${FNAME}_NAME ${vname} PARENT_SCOPE)
	message(" BII_CREATE_ANDROID_TARGET_PROJECT( ${FNAME} )")
	
	BII_CREATE_ANDROID_TARGET_PROJECT(${FNAME})
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# FIND_ANDROID_TOOLS()
# 
# A specific finder for basic android tools 
#  ANDROID command : needed for default apk project creation & update)
#  ANT command : to java compilation and packaging
#  ADB command : allows the apk deploy
#=============================================================================#
function( FIND_ANDROID_TOOLS )

	SET(ANDROID_SDK_TOOLS_NOT_FOUND "\n******************************************************
You should set an environment variable or put in the path the executables 'android', 'ant' and 'adb'
export ANDROID_SDK_TOOLS=/path/to/my-android-sdk/tools
If you don't have it try to download Stand-alone SDK tools from:
	http://developer.android.com/sdk/installing/index.html?pkg=tools
******************************************************")

	if(NOT BII_ANDROID_SDK_TOOL)
		find_program(ANDROID_TOOL android NAMES android android.bat PATHS $ENV{ANDROID_SDK_TOOLS} CMAKE_FIND_ROOT_PATH_BOTH)
		if(NOT ANDROID_TOOL)
			message(FATAL_ERROR "Android tool not found! ${ANDROID_SDK_TOOLS_NOT_FOUND}")
		else()
			message("Android tool found! ${ANDROID_TOOL}")
		endif()
	endif()
	if(NOT BII_ANT_TOOL)
		find_program(ANT_TOOL ant PATHS $ENV{ANDROID_SDK_TOOLS} CMAKE_FIND_ROOT_PATH_BOTH)
		if(NOT ANT_TOOL)
			message(FATAL_ERROR "Ant not found! ${ANDROID_SDK_TOOLS_NOT_FOUND}")
		else()
			message("Ant tool found: ${ANT_TOOL}")
		endif()
	endif()
	if(NOT BII_ADB_TOOL)
		find_program(ADB_TOOL adb PATHS $ENV{ANDROID_SDK_TOOLS} CMAKE_FIND_ROOT_PATH_BOTH)
		if(NOT ADB_TOOL)
			message(FATAL_ERROR "ADB not found! ${NOT_FOUND_ERROR}")
		else()
			message("ADB tool found: ${ADB_TOOL}")
		endif()
	endif()
	set(BII_ANDROID_SDK_TOOL ${ANDROID_TOOL} CACHE PATH "Android tool path")
	set(BII_ANT_TOOL ${ANT_TOOL} CACHE PATH "Ant tool path")
	set(BII_ADB_TOOL ${ADB_TOOL} CACHE PATH "ADB tool path")
endfunction()

#when including biicode.cmake in Android cross compilation, automatically detect the android sdk ndk ant tools
if(ANDROID)
   #unset(BII_ANDROID_SDK_TOOL CACHE)
   #unset(BII_ANT_TOOL CACHE)
   #unset(BII_ADB_TOOL CACHE)
   FIND_ANDROID_TOOLS()
   
endif()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# BII_TO_NATIVE_PATH(path)
#   path is a var name
# converts a string to a path usable by the shell (it is important when cross compiling) 
# 
#=============================================================================#
macro (BII_TO_NATIVE_PATH path)
	FILE(TO_NATIVE_PATH "${${path}}" ${path})
	#DETECTING ANDROID-WINDOWS CROSS-COMPILING
	IF(${CMAKE_GENERATOR} MATCHES "MinGW")
		STRING(REPLACE "/" "\\" ${path} "${${path}}")
	ENDIF()
endmacro()

#=============================================================================#
# [PUBLIC/USER]	[[USER BLOCK CMAKELISTS]
#
# BII_USE_ANDROID_APK_PROJECT(target native_so_lib folder)
#
#		 target  -relative to the block, f.e. : myMain (the real cmake target is user_block_myMain)
#		 native_so_lib -the id ob the dynamic lib (without lib and so extension), that is loaded by the java activity
#        folder    - Relative path to block, f.e. : android-proyect should be interpreted user/block/android-project
#
# In order to correctly build an apk, an android project structure is needed. This command, allows the user android project
# definition. Biicode would only place the resulting dynamic lib of the target into the lib directory of this project. A copy
# of the android project is modified to match the platform and ANDROID API configured
#
#=============================================================================#
macro (BII_USE_ANDROID_APK_PROJECT local_target native_so_lib folder)
	file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/${folder}/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/${local_target}/android)
	set_target_properties(${BII_BLOCK_USER}_${BII_BLOCK_NAME}_${local_target} PROPERTIES OUTPUT_NAME ${native_so_lib})
	message("
		set_target_properties(${BII_BLOCK_USER}_${BII_BLOCK_NAME}_${local_target} PROPERTIES OUTPUT_NAME ${native_so_lib})
		")
	#file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/android/biicode_libname.txt
	#"${native_so_lib}")
endmacro()

macro(BII_CREATE_DEFAULT_ANDROID_TARGET_PROJECT apk_local_target )
  #FIND_ANDROID_TOOLS()
		execute_process(COMMAND ${BII_ANDROID_SDK_TOOL} -s create project	
						--path "${apk_local_target}/android" 
						--target android-${ANDROID_NATIVE_API_LEVEL}
						--name ${apk_local_target} 
						--package com.biicode.${apk_local_target} 
						--activity DummyActivity
						WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
						RESULT_VARIABLE ANDROID_RESULT
						ERROR_VARIABLE ANDROID_ERROR_RESULT
						OUTPUT_VARIABLE ANDROID_VARIABLE_RESULT
						)

	  
		#message("ANDROID COMMAND OUTPUT:${ANDROID_VARIABLE_RESULT}")		
		#message("ANDROID COMMAND RESULT:${ANDROID_RESULT}")
		#message("ANDROID COMMAND ERRORS:${ANDROID_ERROR_RESULT}")
		
		#default android manifest
		# override AndroidManifest.xml 
		set_target_properties(${BII_BLOCK_USER}_${BII_BLOCK_NAME}_${apk_local_target} PROPERTIES OUTPUT_NAME ${apk_local_target})
	file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${apk_local_target}/android/AndroidManifest.xml
    "<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\"\n"
    "  package=\"com.biicode.${apk_local_target}\"\n"
    "  android:versionCode=\"1\"\n"
    "  android:versionName=\"1.0\">\n"
    "  <uses-sdk android:minSdkVersion=\"11\" android:targetSdkVersion=\"${ANDROID_NATIVE_API_LEVEL}\"/>\n"
    "  <uses-feature android:glEsVersion=\"0x00020000\"></uses-feature>"
    "  <application android:label=\"${apk_local_target}\" android:hasCode=\"false\">\n"
    "    <activity android:name=\"android.app.NativeActivity\"\n"
    "      android:label=\"${apk_local_target}\"\n"
    "      android:configChanges=\"orientation|keyboardHidden\">\n"
    "      <meta-data android:name=\"android.app.lib_name\" android:value=\"${apk_local_target}\"/>\n"
    "      <intent-filter>\n"
    "        <action android:name=\"android.intent.action.MAIN\"/>\n"
    "        <category android:name=\"android.intent.category.LAUNCHER\"/>\n"
    "      </intent-filter>\n"
    "    </activity>\n"
    "  </application>\n"
    "</manifest>\n")	
endmacro()

macro(BII_CREATE_ANDROID_TARGET_PROJECT apk_local_target )
set(apk_target ${BII_BLOCK_USER}_${BII_BLOCK_NAME}_${apk_local_target})
set(ANDROID_TARGET_LIB_OUTDIR ${CMAKE_CURRENT_BINARY_DIR}/${apk_local_target}/android/libs/${ANDROID_NDK_ABI_NAME})
set_target_properties(${apk_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY  ${ANDROID_TARGET_LIB_OUTDIR})
set_target_properties(${apk_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${ANDROID_TARGET_LIB_OUTDIR})
set_target_properties(${apk_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_DEBUG ${ANDROID_TARGET_LIB_OUTDIR})		
if(NOT ANT_BUILD_TYPE)
if ("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    set(ANT_BUILD_TYPE "release")
else()
    set(ANT_BUILD_TYPE "debug")
endif()
endif()

#retrieve the lib name from theAndroidManifest
#not needed... it has to be included in the CMAKELIST
if(NOTHING)
SET(ANDROID_LIB_NAME ${apk_local_target})
	IF(EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${apk_local_target}/android/AndroidManifest.xml")
		FILE(STRINGS  "${CMAKE_CURRENT_BINARY_DIR}/${apk_local_target}/android/AndroidManifest.xml" FILE_CONTENT)
		STRING(REGEX MATCH "meta-data android:name=\"android\\.app\\.lib_name\"+[ \n].*android:value=\"[0-9a-zA-Z_]*\"" ANDROID_MANIFEST_LIB_NAME ${FILE_CONTENT})
			#STRING(REGEX MATCH "[^0-9]*[0-9]+\\.[0-9]+\\.[0-9]+.*" _threePartMatch "${_requested_version}")
		if (ANDROID_MANIFEST_LIB_NAME)
			message("FOUND EXPRESION: ${ANDROID_MANIFEST_LIB_NAME}")
			STRING(REGEX REPLACE ".*android:value=\"([0-9a-zA-Z_]*)\"" "\\1" ANDROID_LIB_NAME ${ANDROID_MANIFEST_LIB_NAME})
		endif()
		MESSAGE("ANDROID_MANIFEST_LIB_NAME : ${ANDROID_LIB_NAME}")
	endif()
endif()


add_custom_command(TARGET ${apk_target} COMMAND ${BII_ANDROID_SDK_TOOL} -s update project	
						--path "${apk_local_target}/android" 
						--target android-${ANDROID_NATIVE_API_LEVEL}
						--name ${apk_local_target} --subprojects
						WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
						)
#FILE(MAKE_DIRECTORY ${ANDROID_TARGET_LIB_OUTDIR})
set(apk_location "${CMAKE_CURRENT_BINARY_DIR}/${apk_local_target}/android/bin/${apk_local_target}-debug.apk")
BII_TO_NATIVE_PATH(apk_location)
set(android_project_apk_lib_location "${CMAKE_HOME_DIRECTORY}/../bin/lib${apk_target}.so")
BII_TO_NATIVE_PATH(android_project_apk_lib_location)
set(android_output_apk_dir "${CMAKE_HOME_DIRECTORY}/../bin/${apk_target}.apk")
BII_TO_NATIVE_PATH(android_output_apk_dir)

MESSAGE("POST_BUILD = copy ${apk_lib_location} ${android_project_apk_lib_location}")
add_custom_command(TARGET ${apk_target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${apk_target}> ${android_project_apk_lib_location})

add_custom_command(TARGET ${apk_target} POST_BUILD 
					COMMAND ${BII_ANT_TOOL} ${ANT_BUILD_TYPE} 
					WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${apk_local_target}/android)
add_custom_command(TARGET ${apk_target} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${apk_location} ${android_output_apk_dir})		
message(	"-COMADO PST...>E copy ${apk_location} ${android_output_apk_dir}")
add_custom_command(TARGET ${apk_target} POST_BUILD 
					COMMAND ${BII_ADB_TOOL} install -r bin/${apk_local_target}-debug.apk 
					WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${apk_local_target}/android)
endmacro()


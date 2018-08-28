import React from 'react'
import { Image, StyleSheet } from 'react-native'
import PhotoUpload from 'react-native-photo-upload'

const UploadPhoto = ({onStart, onResponse, imageUri}) => {
    return(
        <PhotoUpload
            onPhotoSelect={avatar => {
            if (avatar) {
                console.log('Image base64 string: ', avatar)
            }
            }}
            onResponse = { onResponse }
            onStart = { onStart }
         >
            <Image
                style={styles.imageStyle}
                resizeMode='cover'
                 source={{
                      uri: imageUri
                }}
            />
      </PhotoUpload>
    )   
}

const styles = StyleSheet.create({
    imageStyle: {
        paddingVertical: 30,
         width: 150,
        height: 150,
        borderRadius: 75
    }
})

export default UploadPhoto

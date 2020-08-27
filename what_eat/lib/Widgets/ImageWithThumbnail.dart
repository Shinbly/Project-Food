import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class ImageThumbnail extends StatelessWidget {
  ImageProvider image;
  ImageProvider thumbnail;
  double width;
  double height;
  BoxFit fit;

  ImageThumbnail({
    @required this.image,
    @required this.thumbnail,
    @required this.width,
    @required this.height,
    @required this.fit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: this.height,
      width: this.width,
      child: FadeInImage(
        placeholder: MemoryImage(kTransparentImage),
        image: this.image,
        height: this.height,
        width: this.width,
        fit: this.fit,
      ),
      decoration: BoxDecoration(
        image: DecorationImage(image: this.thumbnail, fit: fit )
      ) ,
    );
  }
}

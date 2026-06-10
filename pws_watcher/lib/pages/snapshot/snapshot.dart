import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

class SnapshotPage extends StatefulWidget {
  const SnapshotPage(
    this.urlImage,
    this.title, {
    super.key,
    this.description,
    this.download = false,
    this.downloadName,
    this.padding,
    this.backgroundColor,
  });

  final String? title;
  final String? urlImage;
  final String? description;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool download;
  final String? downloadName;

  @override
  State<SnapshotPage> createState() => _SnapshotPageState();
}

class _SnapshotPageState extends State<SnapshotPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _requestCounter = 0;

  @override
  void initState() {
    super.initState();
    imageCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const Key('dismissible'),
      direction: DismissDirection.vertical,
      onDismissed: (_) {
        Navigator.pop(context);
      },
      background: Container(
        color: widget.backgroundColor ?? Colors.black,
      ),
      movementDuration: const Duration(milliseconds: 100),
      resizeDuration: const Duration(milliseconds: 100),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: widget.backgroundColor ?? Colors.black,
        appBar: widget.title != null
            ? AppBar(
                iconTheme: const IconThemeData(color: Colors.white),
                backgroundColor: Colors.black,
                title: Text(
                  widget.title!,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _requestCounter++;
                      });
                    },
                  ),
                  if (widget.download)
                    IconButton(
                      icon: const Icon(Icons.file_download),
                      onPressed: _downloadImageFromUrl,
                    ),
                ],
              )
            : null,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _getPhotoView(),
            if (widget.description != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  color: Colors.black45,
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    widget.description!,
                    textAlign: TextAlign.start,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImageFromUrl() async {
    try {
      PermissionStatus permission;

      if (Platform.isAndroid) {
        permission = await Permission.storage.request();
      } else {
        permission = await Permission.photos.request();
      }

      if (!permission.isGranted) {
        showSimpleNotification(
          const Text("Permesso negato"),
          background: Colors.red,
          foreground: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final response = await http.get(
        Uri.parse(widget.urlImage!),
      );

      if (response.statusCode != 200) {
        throw Exception("Download fallito");
      }

      Directory directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName =
          "${widget.downloadName ?? DateTime.now().millisecondsSinceEpoch}.png";

      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);

      showSimpleNotification(
        Text("Immagine salvata:\n$fileName"),
        background: Colors.green,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
        position: NotificationPosition.bottom,
      );
    } catch (e) {
      debugPrint(e.toString());

      showSimpleNotification(
        const Text("Errore durante il download"),
        background: Colors.red,
        foreground: Colors.white,
        duration: const Duration(seconds: 3),
        position: NotificationPosition.bottom,
      );
    }
  }

  Widget _getPhotoView() {
    final String url = widget.urlImage! +
        (widget.urlImage!.contains("?")
            ? "&n=$_requestCounter"
            : "?n=$_requestCounter");

    return PhotoView.customChild(
      childSize: const Size(100, 100),
      backgroundDecoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Container(
        padding: widget.padding,
        color: Colors.transparent,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 60,
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class WidgetToImage {
  static Future<ByteData> repaintBoundaryToImage(
    GlobalKey key, {
    double pixelRatio = 1.0,
  }) =>
      Future.delayed(
        const Duration(milliseconds: 20),
        () async {
          final repaintBoundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

          final image = await repaintBoundary.toImage(
            pixelRatio: pixelRatio,
          );

          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );

          return byteData!;
        },
      );

  static Future<ByteData> widgetToImage(
    Widget widget, {
    Alignment alignment = Alignment.center,
    required Size size,
    double devicePixelRatio = 1.0,
    double pixelRatio = 1.0,
  }) async {
    final repaintBoundary = RenderRepaintBoundary();

    final renderView = RenderView(
      child: RenderPositionedBox(alignment: alignment, child: repaintBoundary),
      configuration: ViewConfiguration(
        size: size,
        devicePixelRatio: devicePixelRatio,
      ),
      view: WidgetsBinding.instance.platformDispatcher.views.first,
    );

    final pipelineOwner = PipelineOwner();

    pipelineOwner.rootNode = renderView;

    renderView.prepareInitialFrame();

    final buildOwner = BuildOwner(focusManager: FocusManager());

    final rootElement = RenderObjectToWidgetAdapter(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);

    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();

    pipelineOwner.flushCompositingBits();

    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!;
  }
}

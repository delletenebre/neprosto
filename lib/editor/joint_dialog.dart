import 'desktop.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:material_ui/material_ui.dart';

import 'contact.dart';
import 'controller.dart';
import 'controls.dart';
import 'drawing.dart';
import 'joint.dart';
import 'model.dart';
import 'scene.dart';

Future<void> showPartJoint(BuildContext context, Editor editor) async {
  if (editor.selection.length != 2) return;
  final pair = editor.selection.map((id) => editor.project.byId[id]!).toList();
  final result = await cu.showCupertinoDialog<JointPreview>(
    context: context,
    builder: (_) => JointDialog(pair[0], pair[1]),
  );
  if (result == null ||
      !context.mounted ||
      pair.any((b) => editor.project.byId[b.id] != b)) {
    return;
  }
  editor.commit(
    editor.project.edit({
      pair[0].id,
      pair[1].id,
    }, (b) => b.id == result.fixed.id ? result.fixed : result.moving),
  );
}

class JointDialog extends StatefulWidget {
  final Beam a, b;
  const JointDialog(this.a, this.b, {super.key});
  @override
  State<JointDialog> createState() => _JointDialogState();
}

class _JointDialogState extends State<JointDialog> {
  bool endA = true, endB = false, width = true, flip = false;
  double inside = 90;
  @override
  void initState() {
    super.initState();
    var shortest = double.infinity;
    for (final a in [false, true]) {
      for (final b in [false, true]) {
        final distance = faceCenter(
          widget.a,
          0,
          a,
        ).distanceTo(faceCenter(widget.b, 0, b));
        if (distance < shortest) {
          shortest = distance;
          endA = a;
          endB = b;
        }
      }
    }
  }

  Widget end(String name, bool value, ValueChanged<bool> change) => Row(
    children: [
      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      MenuChoice<bool>(
        label: value ? 'Конец' : 'Начало',
        items: const [(false, 'Начало'), (true, 'Конец')],
        change: change,
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    JointPreview? result;
    String? error;
    try {
      result = makeJoint(
        widget.a,
        widget.b,
        firstEnd: endA,
        secondEnd: endB,
        inside: inside,
        bendThroughWidth: width,
        flip: flip,
      );
    } on FormatException catch (ex) {
      error = ex.message;
    }
    final j = result;
    return DeskDialog(
      title: const Text('Угловой стык'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              end(
                'Опора · ${widget.a.name}',
                endA,
                (v) => setState(() => endA = v),
              ),
              end(
                'Переместить · ${widget.b.name}',
                endB,
                (v) => setState(() => endB = v),
              ),
              Row(
                children: [
                  const Expanded(child: Text('Внутренний угол')),
                  SizedBox(
                    width: 94,
                    child: ValueBox(
                      inside,
                      (v) => setState(() => inside = v),
                      unit: '°',
                      live: true,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  MenuChoice<bool>(
                    label: width ? 'В плоскости ширины' : 'В плоскости толщины',
                    items: const [
                      (true, 'В плоскости ширины'),
                      (false, 'В плоскости толщины'),
                    ],
                    change: (v) => setState(() => width = v),
                  ),
                  const Spacer(),
                  iconAction(
                    cu.CupertinoIcons.arrow_left_right,
                    'Обратить направление',
                    () => setState(() => flip = !flip),
                  ),
                ],
              ),
              if (error != null)
                Text(error, style: const TextStyle(color: Color(0xffa34e37))),
              if (j != null) ...[
                SizedBox(
                  height: 164,
                  child: LayoutBuilder(
                    builder: (_, box) {
                      final p = Project('', [j.fixed, j.moving]),
                          plane = WorkPlane(
                            '',
                            Vector3.zero(),
                            widget.a.along,
                            width ? widget.a.across : widget.a.up,
                          );
                      final camera = Camera()
                        ..facePlane(plane)
                        ..fit(p, box.biggest);
                      final scene = Scene(p, camera, box.biggest);
                      return CustomPaint(
                        painter: DrawingPainter(
                          scene: scene,
                          selection: {},
                          plane: plane,
                          grid: false,
                          dimensions: false,
                          gridStep: 50,
                        ),
                        foregroundPainter: _CutLine(j.fixed, endA, camera),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Запил каждого торца · ${mm(j.saw)}° от прямого',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  'Длины короткой и длинной кромок, ${Units.of(context).symbol}',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                for (final b in [j.fixed, j.moving])
                  Builder(
                    builder: (_) {
                      final lengths = edgeLengths(b)..sort();
                      return Row(
                        children: [
                          Expanded(child: Text(b.name)),
                          Text(
                            '${Units.of(context).format(lengths.first)} / ${Units.of(context).format(lengths.last)}',
                            style: mono,
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        DeskButton(
          primary: true,
          onPressed: j == null ? null : () => Navigator.pop(context, j),
          child: const Text('Соединить'),
        ),
      ],
    );
  }
}

class _CutLine extends CustomPainter {
  final Beam beam;
  final bool end;
  final Camera camera;
  _CutLine(this.beam, this.end, this.camera);
  @override
  void paint(Canvas c, Size s) {
    final points = [
      for (final i in faceCorners[end ? 1 : 0])
        camera.project(beam.corner(i), s),
    ];
    c.drawPath(
      Path()..addPolygon(points, true),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xffad593d),
    );
  }

  @override
  bool shouldRepaint(_CutLine old) => true;
}

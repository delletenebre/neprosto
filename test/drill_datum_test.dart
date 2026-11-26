import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/model.dart';

void main() {
  final stock = Beam(
    1,
    'Деталь',
    Vector3(80, 140, 20),
    Vector3(400, 200, 18),
    axis(2),
    axis(0),
  );
  test('A saved project keeps the individual datum and drilling side for each bore', () {
    final faces = [
      const PanelHole(
        99,
        30,
        10,
        depth: 12,
        back: true,
        fromEnd: true,
        datum: (u: 237, v: 30),
      ),
      const PanelHole(72, 46, 6, datum: (u: 40, v: 46)),
    ];
    final edges = [
      for (final edge in PanelEdge.values)
        for (final far in [false, true])
          (
            edge: edge,
            kind: far ? EdgeHoleKind.pushToOpen : EdgeHoleKind.openingSensor,
            datum: (u: edge.length(stock.size) / 2, v: 9.0),
            fromEnd: far,
            back: false,
            offset: edge.length(stock.size) / 2 - 32,
            height: 9.0,
            diameter: 10.0,
            depth: far ? 50.0 : 12.0,
          ),
    ];
    final project = Project(
      'Деталь',
      [stock.copy(holes: faces, edgeHoles: edges)],
      const [],
      LengthUnit.inch,
    );
    final restored = Project.decode(project.encode()).beams.single;
    expect(restored.holes, faces);
    expect(restored.edgeHoles, edges);
    expect(
      restored.holes.first.drills(restored.size).single.entry,
      Vector3(301, 30, 18),
    );
    expect(
      restored.holes.first.centerX(restored.size) -
          restored.holes.first.datum!.u,
      64,
    );
    for (final hole in restored.edgeHoles) {
      final cut = hole.drill(restored.size);
      expect(cut.face, hole.edge.faceIndex);
      expect(cut.entry.z, hole.datum!.v);
      expect(cut.entry[1 - cut.axis] - hole.datum!.u, hole.fromEnd ? 32 : -32);
      expect(cut.depth, hole.depth);
    }
  });

  test('Legacy bores retain their corner and end references without a custom datum', () {
    final edgeJson = {
      'edge': 'far',
      'kind': 'dowel',
      'fromEnd': true,
      'height': 9,
      'offset': 37,
      'diameter': 8,
      'depth': 20,
    };
    final oldProject = Project('Legacy', [stock]).toJson();
    oldProject['beams'] = [
      {
        ...stock.toJson(),
        'holes': [
          {'x': 22, 'y': 90, 'diameter': 35, 'fromFarEdge': true},
        ],
        'edgeHoles': [edgeJson],
      },
    ];
    final restored = Project.decode(Project.fromJson(oldProject).encode())
        .beams
        .single;
    final face = restored.holes.single, edge = restored.edgeHoles.single;
    expect(face.datum, isNull);
    expect(face.toJson().containsKey('datum'), isFalse);
    expect((face.centerX(stock.size), face.centerY(stock.size)), (22, 110));
    expect(edge.datum, isNull);
    expect(edge.toJson(), edgeJson);
    expect(edge.drill(stock.size).entry, Vector3(363, 200, 9));
  });
}

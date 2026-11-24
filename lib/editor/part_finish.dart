import '../l10n/strings.dart';

enum PartTexture {
  wood,
  laminate,
  woodLaminate,
  plywood,
  mdf,
  brushedMetal,
  paintedMetal;

  static const choices = [wood, brushedMetal, paintedMetal];

  PartTexture get choice => switch (this) {
    woodLaminate || plywood => wood,
    laminate || mdf => paintedMetal,
    _ => this,
  };

  String get label => switch (this) {
    wood => editorStrings.naturalWood,
    brushedMetal => editorStrings.metal,
    paintedMetal => editorStrings.solidColor,
    plywood => editorStrings.plywood,
    mdf => editorStrings.mdf,
    woodLaminate || laminate => choice.label,
  };
}

typedef PartFinish = ({PartTexture texture, int rgb});

const woodFinish = (texture: PartTexture.wood, rgb: 0xd7b288);

enum FinishPreset {
  wood(woodFinish),
  whiteBoard((texture: PartTexture.laminate, rgb: 0xf4f2ec)),
  oakBoard((texture: PartTexture.woodLaminate, rgb: 0xb39474)),
  plywood((texture: PartTexture.plywood, rgb: 0xe0bf93)),
  mdf((texture: PartTexture.mdf, rgb: 0xbd9873)),
  aluminum((texture: PartTexture.brushedMetal, rgb: 0xb0b8c1)),
  graphiteSteel((texture: PartTexture.paintedMetal, rgb: 0x484b50));

  const FinishPreset(this.finish);
  final PartFinish finish;

  String get label => switch (this) {
    wood => editorStrings.naturalWood,
    whiteBoard => editorStrings.whiteBoard,
    oakBoard => editorStrings.oakBoard,
    plywood => editorStrings.plywood,
    mdf => editorStrings.mdf,
    aluminum => editorStrings.aluminumProfile,
    graphiteSteel => editorStrings.steelProfile,
  };
}

PartFinish readPartFinish(Object? value) {
  if (value == null) return woodFinish;
  if (value case {'texture': String name, 'rgb': int rgb}
      when rgb >= 0 && rgb <= 0xffffff) {
    for (final texture in PartTexture.values) {
      if (texture.name == name) return (texture: texture, rgb: rgb);
    }
  }
  throw FormatException(editorStrings.invalidPartFinish);
}

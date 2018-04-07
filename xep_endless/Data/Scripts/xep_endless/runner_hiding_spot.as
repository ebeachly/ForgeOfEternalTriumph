void SetParameters() {
    params.AddString("Name", "runner_hiding_spot");
}

void Init()
{
	Object@ obj = ReadObjectFromID(hotspot.GetID());
	obj.SetScale(vec3(0.25,0.25,0.25));
	obj.SetScalable(false);
}

void DrawEditor() {
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    DebugDrawBillboard("Data/UI/xep_endless/thumbs/rabbit_foot.png",
                       obj.GetTranslation(),
                       obj.GetScale()[1]*5.0,
                       vec4(vec3(0.5), 1.0),
                       _delete_on_draw);
}
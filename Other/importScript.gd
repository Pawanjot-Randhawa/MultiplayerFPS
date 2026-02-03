@tool
extends EditorScenePostImport


# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	for n in scene.find_children("*", "MeshInstance3D", true):
		if n.mesh:
			n.create_trimesh_collision()
	return scene # Return the modified root node when you're done.

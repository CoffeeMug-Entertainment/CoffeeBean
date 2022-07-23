#include "Entity.h"

#include "Components.h"

namespace CBE
{
	void Entity::AddTransform()
	{
		transform = new TransformComp();
		transform->ToDefault();
	}

	void Entity::AddModel(Model& newModel)
	{
		modelComp = new ModelComp();
		modelComp->model = newModel;
	}
}

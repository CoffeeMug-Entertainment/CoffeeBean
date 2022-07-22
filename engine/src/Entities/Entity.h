#ifndef CBE_ENTITY_H
#define CBE_ENTITY_H

#include "Renderer/Model.h"
#include <vector>

namespace CBE
{
	struct TransformComp;
	struct ModelComp;

	struct Entity
	{
		void AddTransform();
		void AddModel(Model& newModel);
		TransformComp* transform;
		ModelComp* modelComp;
	};
}

#endif

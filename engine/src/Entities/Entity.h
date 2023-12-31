#ifndef CBE_ENTITY_H
#define CBE_ENTITY_H

#include "Entities/Components.h"
#include "entt/entity/fwd.hpp"
#include <vector>

namespace CBE
{
	struct Entity
	{
		entt::entity enttID;

		void Create();
		CBE::TransformComp& Transform();
	};
}

#endif

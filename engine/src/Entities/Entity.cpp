#include "Entity.h"

#include "Components.h"
#include "App.h"
#include "entt/entt.hpp"

namespace CBE
{
	void Entity::Create()
	{
		this->enttID = App::Instance().m_entityRegistry.create();
		App::Instance().m_entityRegistry.emplace<TransformComp>(enttID).ToDefault();
	}	
}

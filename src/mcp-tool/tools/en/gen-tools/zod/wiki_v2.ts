import { z } from 'zod';
export type wikiV2ToolName =
  | 'wiki.v2.space.create'
  | 'wiki.v2.space.get'
  | 'wiki.v2.space.getNode'
  | 'wiki.v2.space.list'
  | 'wiki.v2.spaceMember.create'
  | 'wiki.v2.spaceMember.delete'
  | 'wiki.v2.spaceMember.list'
  | 'wiki.v2.spaceNode.copy'
  | 'wiki.v2.spaceNode.create'
  | 'wiki.v2.spaceNode.list'
  | 'wiki.v2.spaceNode.move'
  | 'wiki.v2.spaceNode.moveDocsToWiki'
  | 'wiki.v2.spaceNode.updateTitle'
  | 'wiki.v2.spaceSetting.update'
  | 'wiki.v2.task.get';
export const wikiV2SpaceCreate = {
  project: 'wiki',
  name: 'wiki.v2.space.create',
  sdkName: 'wiki.v2.space.create',
  path: '/open-apis/wiki/v2/spaces',
  httpMethod: 'POST',
  description: '[Feishu/Lark]-Docs-Wiki-Wiki space-Create Wiki space-This interface is used to create a Wiki space',
  accessTokens: ['user'],
  schema: {
    data: z.object({
      name: z.string().optional(),
      description: z.string().optional(),
      open_sharing: z.enum(['open', 'closed']).optional(),
    }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceGet = {
  project: 'wiki',
  name: 'wiki.v2.space.get',
  sdkName: 'wiki.v2.space.get',
  path: '/open-apis/wiki/v2/spaces/:space_id',
  httpMethod: 'GET',
  description: '[Feishu/Lark]-Docs-Wiki-Wiki space-Access to Wiki space information',
  accessTokens: ['tenant', 'user'],
  schema: {
    params: z.object({ lang: z.enum(['zh', 'id', 'de', 'en', 'es', 'fr', 'it', 'pt', 'vi', 'ru', 'hi', 'th', 'ko', 'ja', 'zh-HK', 'zh-TW']).optional() }).optional(),
    path: z.object({ space_id: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceGetNode = {
  project: 'wiki',
  name: 'wiki.v2.space.getNode',
  sdkName: 'wiki.v2.space.getNode',
  path: '/open-apis/wiki/v2/spaces/get_node',
  httpMethod: 'GET',
  description: '[Feishu/Lark]-Docs-Wiki-node-Get Wiki node information',
  accessTokens: ['tenant', 'user'],
  schema: {
    params: z.object({
      token: z.string(),
      obj_type: z.enum(['doc', 'docx', 'sheet', 'mindnote', 'bitable', 'file', 'slides', 'wiki']).optional(),
    }),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceList = {
  project: 'wiki',
  name: 'wiki.v2.space.list',
  sdkName: 'wiki.v2.space.list',
  path: '/open-apis/wiki/v2/spaces',
  httpMethod: 'GET',
  description: '[Feishu/Lark]-Docs-Wiki-Wiki space-Get a list of Wiki spaces',
  accessTokens: ['tenant', 'user'],
  schema: {
    params: z.object({ page_size: z.number().optional(), page_token: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceMemberCreate = {
  project: 'wiki',
  name: 'wiki.v2.spaceMember.create',
  sdkName: 'wiki.v2.spaceMember.create',
  path: '/open-apis/wiki/v2/spaces/:space_id/members',
  httpMethod: 'POST',
  description: '[Feishu/Lark]-Docs-Wiki-Space member-Add Wiki space members',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({ member_type: z.string(), member_id: z.string(), member_role: z.string() }),
    params: z.object({ need_notification: z.boolean().optional() }).optional(),
    path: z.object({ space_id: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceMemberDelete = {
  project: 'wiki',
  name: 'wiki.v2.spaceMember.delete',
  sdkName: 'wiki.v2.spaceMember.delete',
  path: '/open-apis/wiki/v2/spaces/:space_id/members/:member_id',
  httpMethod: 'DELETE',
  description: '[Feishu/Lark]-Docs-Wiki-Space member-Delete Wiki space members',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({ member_type: z.string(), member_role: z.string(), type: z.enum(['user', 'chat', 'department']).optional() }),
    path: z.object({ space_id: z.string(), member_id: z.string() }),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceMemberList = {
  project: 'wiki',
  name: 'wiki.v2.spaceMember.list',
  sdkName: 'wiki.v2.spaceMember.list',
  path: '/open-apis/wiki/v2/spaces/:space_id/members',
  httpMethod: 'GET',
  description: '[Feishu/Lark]-Docs-Wiki-Space member-Obtain Wiki space members',
  accessTokens: ['tenant', 'user'],
  schema: {
    params: z.object({ page_size: z.number().optional(), page_token: z.string().optional() }).optional(),
    path: z.object({ space_id: z.string() }),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceNodeCopy = {
  project: 'wiki',
  name: 'wiki.v2.spaceNode.copy',
  sdkName: 'wiki.v2.spaceNode.copy',
  path: '/open-apis/wiki/v2/spaces/:space_id/nodes/:node_token/copy',
  httpMethod: 'POST',
  description: '[Feishu/Lark]-Docs-Wiki-node-Create a node copy',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({ target_parent_token: z.string().optional(), target_space_id: z.string().optional(), title: z.string().optional() }).optional(),
    path: z.object({ space_id: z.string().optional(), node_token: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceNodeCreate = {
  project: 'wiki',
  name: 'wiki.v2.spaceNode.create',
  sdkName: 'wiki.v2.spaceNode.create',
  path: '/open-apis/wiki/v2/spaces/:space_id/nodes',
  httpMethod: 'POST',
  description: '[Feishu/Lark]-Docs-Wiki-node-Create node',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({
      obj_type: z.enum(['doc', 'sheet', 'mindnote', 'bitable', 'file', 'docx', 'slides']),
      parent_node_token: z.string().optional(),
      node_type: z.enum(['origin', 'shortcut']),
      origin_node_token: z.string().optional(),
      title: z.string().optional(),
    }),
    path: z.object({ space_id: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceNodeList = {
  project: 'wiki',
  name: 'wiki.v2.spaceNode.list',
  sdkName: 'wiki.v2.spaceNode.list',
  path: '/open-apis/wiki/v2/spaces/:space_id/nodes',
  httpMethod: 'GET',
  description: '[Feishu/Lark]-Docs-Wiki-node-Get the list of child nodes in Wiki',
  accessTokens: ['tenant', 'user'],
  schema: {
    params: z.object({ page_size: z.number().optional(), page_token: z.string().optional(), parent_node_token: z.string().optional() }).optional(),
    path: z.object({ space_id: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceNodeMove = {
  project: 'wiki',
  name: 'wiki.v2.spaceNode.move',
  sdkName: 'wiki.v2.spaceNode.move',
  path: '/open-apis/wiki/v2/spaces/:space_id/nodes/:node_token/move',
  httpMethod: 'POST',
  description: '[Feishu/Lark]-Docs-Wiki-node-Move node in Wiki',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({ target_parent_token: z.string().optional(), target_space_id: z.string().optional() }).optional(),
    path: z.object({ space_id: z.string(), node_token: z.string() }),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceNodeMoveDocsToWiki = {
  project: 'wiki',
  name: 'wiki.v2.spaceNode.moveDocsToWiki',
  sdkName: 'wiki.v2.spaceNode.moveDocsToWiki',
  path: '/open-apis/wiki/v2/spaces/:space_id/nodes/move_docs_to_wiki',
  httpMethod: 'POST',
  description: '[Feishu/Lark]-Docs-Wiki-Docs-Move cloud document to Wiki',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({
      parent_wiki_token: z.string().optional(),
      obj_type: z.enum(['doc', 'sheet', 'bitable', 'mindnote', 'docx', 'file', 'slides']),
      obj_token: z.string(),
      apply: z.boolean().optional(),
    }),
    path: z.object({ space_id: z.string() }),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceNodeUpdateTitle = {
  project: 'wiki',
  name: 'wiki.v2.spaceNode.updateTitle',
  sdkName: 'wiki.v2.spaceNode.updateTitle',
  path: '/open-apis/wiki/v2/spaces/:space_id/nodes/:node_token/update_title',
  httpMethod: 'POST',
  description: '[Feishu/Lark]-Docs-Wiki-node-Update title',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({ title: z.string() }),
    path: z.object({ space_id: z.string().optional(), node_token: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2SpaceSettingUpdate = {
  project: 'wiki',
  name: 'wiki.v2.spaceSetting.update',
  sdkName: 'wiki.v2.spaceSetting.update',
  path: '/open-apis/wiki/v2/spaces/:space_id/setting',
  httpMethod: 'PUT',
  description: '[Feishu/Lark]-Docs-Wiki-Space settings-Update Wiki space settings',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({ create_setting: z.string().optional(), security_setting: z.string().optional(), comment_setting: z.string().optional() }).optional(),
    path: z.object({ space_id: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2TaskGet = {
  project: 'wiki',
  name: 'wiki.v2.task.get',
  sdkName: 'wiki.v2.task.get',
  path: '/open-apis/wiki/v2/tasks/:task_id',
  httpMethod: 'GET',
  description: '[Feishu/Lark]-Docs-Wiki-Docs-Retrieve the result of Wiki task',
  accessTokens: ['tenant', 'user'],
  schema: {
    params: z.object({ task_type: z.literal('move') }),
    path: z.object({ task_id: z.string().optional() }).optional(),
    useUAT: z.boolean().optional(),
  },
};
export const wikiV2Tools = [
  wikiV2SpaceCreate,
  wikiV2SpaceGet,
  wikiV2SpaceGetNode,
  wikiV2SpaceList,
  wikiV2SpaceMemberCreate,
  wikiV2SpaceMemberDelete,
  wikiV2SpaceMemberList,
  wikiV2SpaceNodeCopy,
  wikiV2SpaceNodeCreate,
  wikiV2SpaceNodeList,
  wikiV2SpaceNodeMove,
  wikiV2SpaceNodeMoveDocsToWiki,
  wikiV2SpaceNodeUpdateTitle,
  wikiV2SpaceSettingUpdate,
  wikiV2TaskGet,
];

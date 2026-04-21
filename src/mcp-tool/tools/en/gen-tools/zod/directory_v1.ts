import { z } from 'zod';
export type directoryV1ToolName =
  | 'directory.v1.collaborationRule.create'
  | 'directory.v1.collaborationRule.delete'
  | 'directory.v1.collaborationRule.list'
  | 'directory.v1.collaborationRule.update'
  | 'directory.v1.collaborationTenant.list'
  | 'directory.v1.collborationShareEntity.list'
  | 'directory.v1.department.create'
  | 'directory.v1.department.delete'
  | 'directory.v1.department.filter'
  | 'directory.v1.department.mget'
  | 'directory.v1.department.patch'
  | 'directory.v1.department.search'
  | 'directory.v1.employee.create'
  | 'directory.v1.employee.delete'
  | 'directory.v1.employee.filter'
  | 'directory.v1.employee.mget'
  | 'directory.v1.employee.patch'
  | 'directory.v1.employee.regular'
  | 'directory.v1.employee.resurrect'
  | 'directory.v1.employee.search'
  | 'directory.v1.employee.toBeResigned';
export const directoryV1CollaborationRuleCreate = {
  project: 'directory',
  name: 'directory.v1.collaborationRule.create',
  sdkName: 'directory.v1.collaborationRule.create',
  path: '/open-apis/directory/v1/collaboration_rules',
  httpMethod: 'POST',
  description:
    '[Feishu/Lark]-Trust Party-Collaboration rules-Add collaboration rules-Admin perspective Added collaboration rules. Users need to have trusted party administrator role',
  accessTokens: ['tenant', 'user'],
  schema: {
    data: z.object({
      subjects: z
        .object({
          open_user_ids: z
            .array(z.string())
            .describe('User open id, which can be obtained from our Contacts/organizational structure interfaces')
            .optional(),
          open_department_ids: z
            .array(z.string())
            .describe(
              'Department open id, 0 represents all members, which can be obtained from our Contacts/organizational structure interfaces',
            )
            .optional(),
          open_group_ids: z
            .array(z.string())
            .describe('The user group open id can be obtained from our Contacts/organizational structure interfaces')
            .optional(),
        })
        .describe('The sum of the number of entities needs to be less than 100'),
      objects: z
        .object({
          open_user_ids: z.array(z.string()).describe('User open id').optional(),
          open_department_ids: z.array(z.string()).describe('Department open id, 0 represents all members').optional(),
          open_group_ids: z.array(z.string()).describe('Group open id').optional(),
        })
        .describe('The sum of the number of entities needs to be less than 100'),
    }),
    params: z.object({ target_tenant_key: z.string().describe("The other tenant's tenant key") }),
    useUAT: z.boolean().describe('Use user access token, otherwise use tenant access token').optional(),
  },
};

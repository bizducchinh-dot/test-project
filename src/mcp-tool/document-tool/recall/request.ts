import { DocumentRecallToolOptions } from './type';
import { commonHttpInstance } from '../../../utils/http-instance';

export const recallDeveloperDocument = async (query: string, options: DocumentRecallToolOptions) => {
  try {
    const { domain, count = 3 } = options;
    const searchEndpoint = `${domain}/document_portal/v1/recall`;
    const payload = {
      question: query,
    };
    const response = await commonHttpInstance.post(searchEndpoint, payload, {
      timeout: 10000,
    });

    let results = response.data.chunks || [];
    return results.slice(0, count);
  } catch (error) {
    throw error;
  }
};

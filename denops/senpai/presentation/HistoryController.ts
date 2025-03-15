import { GetHistory } from "../usecase/GetHistory.ts";

export class HistoryController {
  async execute() {
    return await new GetHistory().execute();
    /*
[
  {
    "id": "/home/eetann/ghq/dev/deno-20250315213114",
    "resourceId": "senpai",
    "title": "テストメッセージ",
    "createdAt": "2025-03-15T12:31:39.062Z",
    "updatedAt": "2025-03-15T12:31:39.062Z",
    "metadata": null
  },
  {
    "id": "/home/eetann/ghq/dev/deno-20250315215248",
    "resourceId": "senpai",
    "title": "Japanese curry ingredients list",
    "createdAt": "2025-03-15T12:53:12.231Z",
    "updatedAt": "2025-03-15T12:53:12.231Z",
    "metadata": null
  }
]
     */
  }
}

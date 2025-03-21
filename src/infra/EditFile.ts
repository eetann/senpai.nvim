import {
	type IEditFile,
	inputSchema,
	outputSchema,
} from "@/usecase/shared/IEditFile";
import { createTool } from "@mastra/core/tools";
import type { z } from "zod";

// 一時ファイルに書き込み、そのパスを返す
// エディタ側でdiffビューを使って反映させる
// 変更内容はチャットにも表示する

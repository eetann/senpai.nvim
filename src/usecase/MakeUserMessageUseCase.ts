export class MakeUserMessageUseCase {
	// TODO: Correct output to message
	execute(text: string): string[] {
		const pattern = /`@([^`]+)`/g;
		const matches = [...text.matchAll(pattern)];
		return matches.map((match) => match[1]);
	}
}

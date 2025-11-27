import OpenAI from "openai";

// API 키는 환경 변수(OPENAI_API_KEY)에서 자동으로 읽어옵니다.
const client = new OpenAI();

async function main() {
  const completion = await client.chat.completions.create({
    // messages 형식으로 질문을 전달해야 합니다.
    messages: [
      { role: "user", content: "Write a one-sentence bedtime story about a unicorn." }
    ],
    model: "gpt-3.5-turbo", // 실제 사용 가능한 모델명으로 수정
  });

  console.log(completion.choices[0].message.content);
}

main();
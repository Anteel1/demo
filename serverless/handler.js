function randomDigits(n = 8) {
  let s = "";
  for (let i = 0; i < n; i++) {
    s += Math.floor(Math.random() * 10).toString();
  }
  return s;
}

exports.handler = async (event) => {
  const failures = [];

  for (const record of event.Records ?? []) {
    try {
      const bodyText = record.body || "{}";
      let payload;
      try {
        payload = JSON.parse(bodyText);
      } catch {
        payload = { raw: bodyText };
      }

      const code = randomDigits(8);
      console.log("MessageId:", record.messageId, "Payload:", payload, "Generated8:", code);

    } catch (err) {
      console.error("Process FAIL:", err, "msgId:", record.messageId);
      failures.push({ itemIdentifier: record.messageId });
    }
  }

  if (failures.length) {
    return { batchItemFailures: failures };
  }
  return {};
};
``

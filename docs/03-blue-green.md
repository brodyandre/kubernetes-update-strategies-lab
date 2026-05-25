# Blue / Green

## Objetivo da estratégia

Demonstrar uma atualização em que duas versões da aplicação coexistem ao mesmo tempo, permitindo validação prévia da nova versão e troca controlada do tráfego.

## Explicação simples

Na estratégia `Blue / Green`, a versão atual continua ativa enquanto a nova versão é preparada em paralelo. Depois de validar a nova versão, o tráfego é redirecionado para ela. Isso torna o processo de promoção e rollback mais claro.

## Como funciona no Kubernetes

Neste laboratório, a estratégia usa:

- Deployment ativo inicial: `blue-deployment`
- Deployment de preview: `green-deployment`
- Namespace: `update-strategies`
- Service ativo: `blue-green-active`
- Service de preview: `blue-green-preview`
- Manifest de troca: `manifests/03-blue-green/service-switch-green.yaml`

O Service ativo começa apontando para `version: blue`, enquanto o Service de preview aponta para `version: green`. A troca acontece quando o selector do Service ativo passa a apontar para a versão `green`.

## Comandos para executar

Pré-requisitos do laboratório:

```bash
./scripts/setup.sh
./scripts/build-images.sh
./scripts/import-images-k3d.sh
```

Aplicar a estratégia:

```bash
./scripts/apply-blue-green.sh
```

Trocar o tráfego ativo para a versão `green`:

```bash
kubectl apply -f manifests/03-blue-green/service-switch-green.yaml
```

## Comandos para verificar

```bash
kubectl get deployments -n update-strategies
kubectl get pods -n update-strategies -l app=blue-green-demo -o wide
kubectl get svc -n update-strategies
kubectl get endpoints -n update-strategies
kubectl describe svc blue-green-active -n update-strategies
kubectl describe svc blue-green-preview -n update-strategies
```

## O que observar durante a execução

- As duas versões ficam disponíveis ao mesmo tempo.
- O Service ativo inicialmente envia tráfego para a versão `blue`.
- O Service de preview permite validar a versão `green` antes da promoção.
- A troca de tráfego ocorre sem recriar os Deployments, apenas alterando o selector do Service ativo.

## Vantagens

- Facilita validação da nova versão antes da ativação.
- Permite rollback rápido ao voltar o Service para a versão anterior.
- Separa claramente ambiente ativo e ambiente de preview.
- Torna a promoção mais controlada e explícita.

## Limitações

- Exige mais recursos, porque duas versões ficam ativas em paralelo.
- A operação depende de boa organização de labels e selectors.
- Pode ser excessiva para cenários muito simples.

## Cenário recomendado de uso

Essa estratégia costuma ser adequada quando:

- a nova versão precisa ser validada antes de receber tráfego principal
- rollback rápido é uma exigência importante
- o ambiente suporta custo extra de manter duas versões em paralelo
- o time quer uma separação clara entre ambiente ativo e preview

## Evidências, prints ou logs

Registre evidências que mostrem a coexistência e a troca de tráfego:

- print de `kubectl get svc -n update-strategies`
- print de `kubectl get endpoints -n update-strategies`
- saída de `kubectl describe svc blue-green-active -n update-strategies`
- comparação antes e depois da aplicação de `service-switch-green.yaml`
- evidência de que `blue-green-preview` já apontava para a versão `green`

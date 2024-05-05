library(h2o)
library(ggplot2)

h2o.init()
model <- h2o.loadModel("./GBM_1_AutoML_1_20240504_195003")

print("Variable Importance:")
print(h2o.varimp(model))

p1 <- h2o.varimp_plot(model)

ggsave("var_imp.pdf", plot = p1)

h2o.shutdown(prompt=FALSE)
